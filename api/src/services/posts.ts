import { Types } from 'mongoose';
import { Post, type IPost, type VoteType } from '../models/Post.js';
import { Vote } from '../models/Vote.js';
import { User } from '../models/User.js';
import { applyVote, decayE, sigmoid, statusFromConfidence, expiryFromE, E_INITIAL } from '../confidence.js';
import { resolveLocation } from '../locations.js';
import { AppError } from '../errors.js';

type NewPost = Pick<IPost, 'foodName' | 'type' | 'dietaryTags' | 'location' | 'locationDetail' | 'imageKey'>;

type PopulatedAuthor = { _id: Types.ObjectId; displayName: string; avatarKey?: string };

export async function createPost(authorId: string, data: NewPost) {
    const now = new Date();
    const post = await Post.create({ ...data, author: authorId, lastUpdate: now, expiresAt: expiryFromE(E_INITIAL, now) });
    const author = await User.findById(authorId).select('displayName avatarKey').lean();
    return {
        ...post.toObject(),
        location: resolveLocation(post.location),
        authorName: author?.displayName,
        authorAvatarKey: author?.avatarKey,
    };
}

export async function listFeed() {
    const now = new Date();
    const posts = await Post.find({ expiresAt: { $gt: now } })
        .sort({ expiresAt: -1 })
        .populate<{ author: PopulatedAuthor }>('author', 'displayName avatarKey')
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

    if (await Vote.exists({ post: postId, user: userId })) {
        throw new AppError(409, 'You have already voted on this post');
    }

    const minutes = (now.getTime() - post.lastUpdate.getTime()) / 60000;
    const E = applyVote(decayE(post.E, minutes), type);
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

    return { confidence, status, tallies };
}