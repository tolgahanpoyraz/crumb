import { Post, type IPost, type VoteType } from '../models/Post.js';
import { applyVote, decayE, sigmoid, statusFromConfidence, expiryFromE, E_INITIAL } from '../confidence.js';
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

    if (post.votes.some((v) => v.user.toString() === userId)) {
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