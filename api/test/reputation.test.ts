import { describe, it, expect, vi } from 'vitest';
import request from 'supertest';

vi.mock('../src/services/email.js', () => ({
    sendVerificationEmail: vi.fn().mockResolvedValue(undefined),
    sendPasswordResetEmail: vi.fn().mockResolvedValue(undefined),
}));

vi.mock('../src/services/uploads.js', () => ({
    createUploadUrl: vi.fn().mockResolvedValue({ url: 'https://signed.example/put', key: 'posts/abc.jpg' }),
}));

import { server } from './server.js';
import { User } from '../src/models/User.js';
import { ReputationEvent } from '../src/models/ReputationEvent.js';
import { sendVerificationEmail } from '../src/services/email.js';
import { tierFor, nextTierAt, TIER_THRESHOLDS } from '../src/reputation.js';

const mockedVerifyEmail = vi.mocked(sendVerificationEmail);

const LOCATION = 'student-union';

let userCount = 0;

async function authUser(): Promise<{ token: string; id: string }> {
    const email = `rep${userCount++}@example.com`;
    const password = 'hunter2pw';
    const displayName = 'Testy';

    await request(server).post('/api/auth/register').send({ displayName, email, password });

    const { calls } = mockedVerifyEmail.mock;
    const token = calls[calls.length - 1][1] as string;
    await request(server).get('/api/auth/verify').query({ token });

    const res = await request(server).post('/api/auth/login').send({ email, password });
    return { token: res.body.token as string, id: res.body.user.id as string };
}

function createPost(token: string, body: Record<string, unknown> = {}) {
    return request(server)
        .post('/api/posts')
        .set('Authorization', `Bearer ${token}`)
        .send({ foodName: 'Bagels', type: 'snacks', location: LOCATION, ...body });
}

function vote(token: string, postId: string, type: string) {
    return request(server)
        .post(`/api/posts/${postId}/vote`)
        .set('Authorization', `Bearer ${token}`)
        .send({ type });
}

describe('tierFor', () => {
    it('maps reputation to the highest crossed threshold', () => {
        expect(tierFor(0)).toBe(0);
        expect(tierFor(49)).toBe(0);
        expect(tierFor(50)).toBe(1);
        expect(tierFor(149)).toBe(1);
        expect(tierFor(150)).toBe(2);
        expect(tierFor(399)).toBe(2);
        expect(tierFor(400)).toBe(3);
        expect(tierFor(10000)).toBe(3);
    });

    it('clamps negative reputation to tier 0', () => {
        expect(tierFor(-1)).toBe(0);
        expect(tierFor(-500)).toBe(0);
    });
});

describe('nextTierAt', () => {
    it('returns the next threshold below the top tier', () => {
        expect(nextTierAt(0)).toBe(50);
        expect(nextTierAt(49)).toBe(50);
        expect(nextTierAt(50)).toBe(150);
        expect(nextTierAt(150)).toBe(400);
        expect(nextTierAt(399)).toBe(400);
    });

    it('returns null at the top tier', () => {
        expect(nextTierAt(400)).toBeNull();
        expect(nextTierAt(9999)).toBeNull();
    });
});

describe('self-vote guard', () => {
    it('rejects voting on your own drop with 403 and records nothing', async () => {
        const author = await authUser();
        const { body } = await createPost(author.token);
        const res = await vote(author.token, body.post._id, 'present');
        expect(res.status).toBe(403);
        expect(await ReputationEvent.countDocuments()).toBe(0);
    });
});

describe('vote awards', () => {
    it('a present vote by another user awards voter +2 and author +10', async () => {
        const author = await authUser();
        const voter = await authUser();
        const { body } = await createPost(author.token);
        await vote(voter.token, body.post._id, 'present').expect(200);

        expect((await User.findById(voter.id))?.reputation).toBe(2);
        expect((await User.findById(author.id))?.reputation).toBe(10);
        expect(await ReputationEvent.countDocuments({ user: voter.id, reason: 'vote-cast' })).toBe(1);
        expect(await ReputationEvent.countDocuments({ user: author.id, reason: 'confirmed-drop' })).toBe(1);
    });

    it('caps author confirm awards at the first 3 present votes', async () => {
        const author = await authUser();
        const { body } = await createPost(author.token);
        for (let i = 0; i < 5; i++) {
            const voter = await authUser();
            await vote(voter.token, body.post._id, 'present').expect(200);
        }
        expect(await ReputationEvent.countDocuments({ user: author.id, reason: 'confirmed-drop' })).toBe(3);
        expect((await User.findById(author.id))?.reputation).toBe(30);
    });

    it('penalizes a phantom post exactly once', async () => {
        const author = await authUser();
        const v1 = await authUser();
        const v2 = await authUser();
        const v3 = await authUser();
        const { body } = await createPost(author.token);

        await vote(v1.token, body.post._id, 'gone').expect(200);
        await vote(v2.token, body.post._id, 'gone').expect(200);
        expect((await User.findById(author.id))?.reputation).toBe(-15);

        await vote(v3.token, body.post._id, 'gone').expect(200);
        expect((await User.findById(author.id))?.reputation).toBe(-15);
        expect(await ReputationEvent.countDocuments({ user: author.id, reason: 'phantom-post' })).toBe(1);
    });
});

describe('reputation-weighted confidence', () => {
    it('a trusted voter moves confidence more than a tier-0 voter', async () => {
        const authorA = await authUser();
        const trusted = await authUser();
        await User.updateOne({ _id: trusted.id }, { $set: { reputation: 400 } });
        const { body: a } = await createPost(authorA.token);
        const trustedRes = await vote(trusted.token, a.post._id, 'present');

        const authorB = await authUser();
        const plain = await authUser();
        const { body: b } = await createPost(authorB.token);
        const plainRes = await vote(plain.token, b.post._id, 'present');

        expect(trustedRes.body.confidence).toBeGreaterThan(plainRes.body.confidence);
    });

    it('a trusted author gets a higher prior and later expiry', async () => {
        const trusted = await authUser();
        await User.updateOne({ _id: trusted.id }, { $set: { reputation: 400 } });
        const plain = await authUser();

        const { body: hi } = await createPost(trusted.token);
        const { body: lo } = await createPost(plain.token);

        expect(hi.post.authorTier).toBe(3);
        expect(lo.post.authorTier).toBe(0);
        expect(hi.post.E).toBeGreaterThan(lo.post.E);
        expect(new Date(hi.post.expiresAt).getTime()).toBeGreaterThan(new Date(lo.post.expiresAt).getTime());
    });
});

describe('GET /api/users/leaderboard', () => {
    it('requires authentication', async () => {
        const res = await request(server).get('/api/users/leaderboard');
        expect(res.status).toBe(401);
    });

    it('ranks users by weekly points and excludes events older than 7 days', async () => {
        const a = await authUser();
        const b = await authUser();
        const c = await authUser();

        await ReputationEvent.create({ user: a.id, delta: 30, reason: 'vote-cast' });
        await ReputationEvent.create({ user: b.id, delta: 20, reason: 'vote-cast' });
        await ReputationEvent.create({ user: c.id, delta: 10, reason: 'vote-cast' });
        // Backdated beyond the 7-day window: must not count toward the leaderboard.
        await ReputationEvent.create({
            user: c.id,
            delta: 100,
            reason: 'vote-cast',
            createdAt: new Date(Date.now() - 8 * 24 * 60 * 60 * 1000),
        });

        const res = await request(server)
            .get('/api/users/leaderboard')
            .set('Authorization', `Bearer ${b.token}`);
        expect(res.status).toBe(200);

        expect(res.body.entries.map((e: { userId: string }) => e.userId)).toEqual([a.id, b.id, c.id]);
        expect(res.body.entries.map((e: { weeklyPoints: number }) => e.weeklyPoints)).toEqual([30, 20, 10]);
        expect(res.body.entries[0]).toMatchObject({ displayName: 'Testy', rank: 1 });
        expect(res.body.me).toMatchObject({ rank: 2, weeklyPoints: 20 });
    });

    it('reports a null rank for a caller with no weekly points', async () => {
        const a = await authUser();
        const me = await authUser();
        await ReputationEvent.create({ user: a.id, delta: 30, reason: 'vote-cast' });

        const res = await request(server)
            .get('/api/users/leaderboard')
            .set('Authorization', `Bearer ${me.token}`);
        expect(res.body.me.rank).toBeNull();
        expect(res.body.me.weeklyPoints).toBe(0);
    });
});

describe('GET /api/auth/me reputation fields', () => {
    it('includes reputation, tier, and nextTierAt', async () => {
        const user = await authUser();
        const res = await request(server).get('/api/auth/me').set('Authorization', `Bearer ${user.token}`);
        expect(res.body.user).toMatchObject({
            reputation: 0,
            tier: 0,
            nextTierAt: TIER_THRESHOLDS[1],
        });
    });
});
