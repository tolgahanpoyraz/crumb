import { Types } from 'mongoose';
import { Post, type IPost, type VoteType } from '../models/Post.js';
import { Vote } from '../models/Vote.js';
import { User } from '../models/User.js';
import { applyVote, decayE, sigmoid, statusFromConfidence, expiryFromE, E_INITIAL } from '../confidence.js';
import { tierFor, TIER_PRIOR_BONUS, TIER_VOTE_MULTIPLIER, VOTE_AWARD, CONFIRM_AWARD, CONFIRM_CAP, PHANTOM_PENALTY } from '../reputation.js';
import { award } from './reputation.js';
import { resolveLocation } from '../locations.js';
import { AppError } from '../errors.js';

type NewPost = Pick<IPost, 'foodName' | 'type' | 'dietaryTags' | 'location' | 'locationDetail' | 'imageKey'>;

type PopulatedAuthor = { _id: Types.ObjectId; displayName: string; avatarKey?: string; reputation: number };

export async function createPost(authorId: string, data: NewPost) {
    const now = new Date();
    const author = await User.findById(authorId).select('displayName avatarKey reputation').lean();
    const authorTier = tierFor(author?.reputation ?? 0);
    const E = E_INITIAL + TIER_PRIOR_BONUS[authorTier];
    const confidence = sigmoid(E);
    const post = await Post.create({
        ...data,
        author: authorId,
        E,
        status: statusFromConfidence(confidence),
        lastUpdate: now,
        expiresAt: expiryFromE(E, now),
    });
    return {
        ...post.toObject(),
        location: resolveLocation(post.location),
        confidence,
        authorName: author?.displayName,
        authorAvatarKey: author?.avatarKey,
        authorTier,
    };
}

export async function listFeed() {
    const now = new Date();
    const posts = await Post.find({ expiresAt: { $gt: now } })
        .sort({ expiresAt: -1 })
        .populate<{ author: PopulatedAuthor }>('author', 'displayName avatarKey reputation')
        .lean();
    return posts.map((post) => {
        const minutes = (now.getTime() - new Date(post.lastUpdate).getTime()) / 60000;
        const confidence = sigmoid(decayE(post.E, minutes));
        const author = post.author;
        return {
            ...post,
            author: author._id.toString(),
            authorName: author.displayName,
            authorAvatarKey: author.avatarKey,
            authorTier: tierFor(author.reputation ?? 0),
            location: resolveLocation(post.location),
            confidence,
            status: statusFromConfidence(confidence),
        };
    });
}

export async function deletePost(postId: string, userId: string) {
    const post = await Post.findById(postId);

    if (!post) {
        throw new AppError(404, 'Post not found');
    }

    if (post.author.toString() !== userId) {
        throw new AppError(403, 'You can only delete your own posts');
    }

    await post.deleteOne();
    await Vote.deleteMany({ post: postId });
}

export async function vote(postId: string, userId: string, type: VoteType) {
    const now = new Date();
    const post = await Post.findById(postId);

    if (!post) {
        throw new AppError(404, 'Post not found');
    }

    if (post.author.toString() === userId) {
        throw new AppError(403, "You can't vote on your own drop");
    }

    if (await Vote.exists({ post: postId, user: userId })) {
        throw new AppError(409, 'You have already voted on this post');
    }

    const voter = await User.findById(userId).select('reputation').lean();
    const minutes = (now.getTime() - post.lastUpdate.getTime()) / 60000;
    const E = applyVote(decayE(post.E, minutes), type, TIER_VOTE_MULTIPLIER[tierFor(voter?.reputation ?? 0)]);
    const confidence = sigmoid(E);
    const status = statusFromConfidence(confidence);
    const expiresAt = expiryFromE(E, now);
    const tallies = {
        present: post.tallies.present + (type === 'present' ? 1 : 0),
        gone: post.tallies.gone + (type === 'gone' ? 1 : 0),
    };

    try {
        await Vote.create({ post: postId, user: userId, type, expiresAt });
    } catch (err) {
        if ((err as { code?: number }).code === 11000) {
            throw new AppError(409, 'You have already voted on this post');
        }
        throw err;
    }

    await Post.updateOne(
        { _id: postId },
        {
            $inc: { [`tallies.${type}`]: 1 },
            $set: { E, status, lastUpdate: now, expiresAt },
        },
    );

    await Vote.updateMany({ post: postId }, { $set: { expiresAt } });

    const authorId = post.author.toString();
    await award(userId, VOTE_AWARD, 'vote-cast', postId);

    if (type === 'present' && tallies.present <= CONFIRM_CAP) {
        await award(authorId, CONFIRM_AWARD, 'confirmed-drop', postId);
    }

    if (type === 'gone' && tallies.gone >= 2 && tallies.present === 0) {
        // Guarded flip so the phantom penalty fires exactly once, even under concurrent gone votes.
        const flipped = await Post.findOneAndUpdate(
            { _id: postId, authorPenalized: false },
            { $set: { authorPenalized: true } },
        );
        if (flipped) {
            await award(authorId, PHANTOM_PENALTY, 'phantom-post', postId);
        }
    }

    return { confidence, status, tallies };
}