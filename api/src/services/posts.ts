import { Post, type IPost, type VoteType } from '../models/Post.js';
import { applyVote, reverseVote, decayE, sigmoid, statusFromConfidence, expiryFromE, E_INITIAL } from '../confidence.js';
import { AppError } from '../errors.js';

type NewPost = Pick<IPost, 'foodName' | 'location' | 'badges' | 'imageKey'>;

export async function createPost(authorId: string, data: NewPost) {
    const now = new Date();
    return Post.create({ ...data, author: authorId, lastUpdate: now, expiresAt: expiryFromE(E_INITIAL, now) });
}

export async function listFeed() {
    const now = new Date();
    const posts = await Post.find({ expiresAt: { $gt: now } }).sort({ expiresAt: -1 }).lean();
    return posts.map((post) => {
        const minutes = (now.getTime() - new Date(post.lastUpdate).getTime()) / 60000;
        const confidence = sigmoid(decayE(post.E, minutes));
        return { ...post, confidence, status: statusFromConfidence(confidence) };
    });
}

export async function vote(postId: string, userId: string, type: VoteType) {
    const now = new Date();
    const post = await Post.findById(postId).select('+votes');

    if (!post) {
        throw new AppError(404, 'Post not found');
    }

    const existingVote = post.votes.find((v) => v.user.toString() === userId);
    const minutes = (now.getTime() - post.lastUpdate.getTime()) / 60000;
    const decayed = decayE(post.E, minutes);

    // Re-selecting the same option is a no-op - nothing to change.
    if (existingVote && existingVote.type === type) {
        const confidence = sigmoid(decayed);
        return { confidence, status: statusFromConfidence(confidence), tallies: post.tallies };
    }

    const E = existingVote ? applyVote(reverseVote(decayed, existingVote.type), type) : applyVote(decayed, type);
    const confidence = sigmoid(E);
    const status = statusFromConfidence(confidence);
    const expiresAt = expiryFromE(E, now);

    if (existingVote) {
        // Switching an existing vote to the other option: move the tally over.
        const tallies = {
            present: post.tallies.present + (type === 'present' ? 1 : 0) - (existingVote.type === 'present' ? 1 : 0),
            gone: post.tallies.gone + (type === 'gone' ? 1 : 0) - (existingVote.type === 'gone' ? 1 : 0),
        };

        const res = await Post.updateOne(
            { _id: postId, 'votes.user': userId, 'votes.type': existingVote.type },
            {
                $set: { 'votes.$.type': type, 'votes.$.at': now, E, status, lastUpdate: now, expiresAt },
                $inc: { [`tallies.${existingVote.type}`]: -1, [`tallies.${type}`]: 1 },
            },
        );
        if (res.matchedCount === 0) {
            throw new AppError(409, 'Your vote changed elsewhere, please try again');
        }

        return { confidence, status, tallies };
    }

    const tallies = {
        present: post.tallies.present + (type === 'present' ? 1 : 0),
        gone: post.tallies.gone + (type === 'gone' ? 1 : 0),
    };

    const res = await Post.updateOne(
        { _id: postId, 'votes.user': { $ne: userId } },
        {
            $push: { votes: { user: userId, type, at: now } },
            $inc: { [`tallies.${type}`]: 1 },
            $set: { E, status, lastUpdate: now, expiresAt },
        },
    );
    if (res.matchedCount === 0) {
        throw new AppError(409, 'You have already voted on this post');
    }

    return { confidence, status, tallies };
}