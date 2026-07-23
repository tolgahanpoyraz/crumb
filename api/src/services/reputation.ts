import { Types } from 'mongoose';
import { ReputationEvent, type ReputationReason } from '../models/ReputationEvent.js';
import { User } from '../models/User.js';
import { tierFor } from '../reputation.js';

const WEEK_MS = 7 * 24 * 60 * 60 * 1000;

export async function award(userId: string, delta: number, reason: ReputationReason, postId?: string): Promise<void> {
    await ReputationEvent.create({ user: userId, delta, reason, post: postId });
    await User.updateOne({ _id: userId }, { $inc: { reputation: delta } });
}

export async function getLeaderboard(meUserId: string) {
    const now = new Date();
    const weekAgo = new Date(now.getTime() - WEEK_MS);

    const sums = await ReputationEvent.aggregate<{ _id: Types.ObjectId; weeklyPoints: number }>([
        { $match: { createdAt: { $gte: weekAgo } } },
        { $group: { _id: '$user', weeklyPoints: { $sum: '$delta' } } },
        { $sort: { weeklyPoints: -1 } },
    ]);

    // Ties share a rank: strictly-higher count means equal sums get the same rank.
    const rankOf = (points: number): number => 1 + sums.filter((s) => s.weeklyPoints > points).length;

    const top = sums.slice(0, 10);
    const users = await User.find({ _id: { $in: top.map((s) => s._id) } })
        .select('displayName avatarKey reputation')
        .lean();
    const byId = new Map(users.map((u) => [u._id.toString(), u]));

    // Events can outlive their user; a deleted account must not hold a slot.
    const entries = top.flatMap((s) => {
        const user = byId.get(s._id.toString());
        if (!user) {
            return [];
        }
        return [{
            userId: s._id.toString(),
            displayName: user.displayName,
            avatarKey: user.avatarKey,
            weeklyPoints: s.weeklyPoints,
            tier: tierFor(user.reputation ?? 0),
            rank: rankOf(s.weeklyPoints),
        }];
    });

    const me = await User.findById(meUserId).select('reputation').lean();
    const myPoints = sums.find((s) => s._id.toString() === meUserId.toString())?.weeklyPoints ?? 0;

    return {
        entries,
        me: {
            rank: myPoints > 0 ? rankOf(myPoints) : null,
            weeklyPoints: myPoints,
            reputation: me?.reputation ?? 0,
            tier: tierFor(me?.reputation ?? 0),
        },
    };
}
