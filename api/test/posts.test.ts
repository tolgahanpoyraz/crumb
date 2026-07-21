import { describe, it, expect, vi } from 'vitest';
import request from 'supertest';

vi.mock('../src/services/email.js', () => ({
    sendVerificationEmail: vi.fn().mockResolvedValue(undefined),
    sendPasswordResetEmail: vi.fn().mockResolvedValue(undefined),
}));

vi.mock('../src/services/uploads.js', () => ({
    createUploadUrl: vi.fn().mockResolvedValue({ url: 'https://signed.example/put', key: 'posts/abc.jpg' }),
}));

import app from '../src/app.js';
import { Post } from '../src/models/Post.js';
import { sendVerificationEmail } from '../src/services/email.js';

const mockedVerifyEmail = vi.mocked(sendVerificationEmail);

let userCount = 0;

async function authUser(): Promise<string> {
    const email = `user${userCount++}@example.com`;
    const password = 'hunter2pw';
    await request(app).post('/api/auth/register').send({ email, password });
    const { calls } = mockedVerifyEmail.mock;
    const token = calls[calls.length - 1][1] as string;
    await request(app).get('/api/auth/verify').query({ token });
    const res = await request(app).post('/api/auth/login').send({ email, password });
    return res.body.token as string;
}

function createPost(token: string, body: Record<string, unknown> = {}) {
    return request(app)
        .post('/api/posts')
        .set('Authorization', `Bearer ${token}`)
        .send({ foodName: 'Bagels', location: 'HEC 101', ...body });
}

function vote(token: string, postId: string, type: string) {
    return request(app)
        .post(`/api/posts/${postId}/vote`)
        .set('Authorization', `Bearer ${token}`)
        .send({ type });
}

describe('POST /api/posts', () => {
    it('requires authentication', async () => {
        const res = await request(app).post('/api/posts').send({ foodName: 'Pizza', location: 'HEC 101' });
        expect(res.status).toBe(401);
    });

    it('creates a fresh post with a future expiry', async () => {
        const token = await authUser();
        const res = await createPost(token, { foodName: 'Pizza', badges: ['pizza'] });
        expect(res.status).toBe(201);
        expect(res.body.post).toMatchObject({ foodName: 'Pizza', location: 'HEC 101', status: 'fresh' });
        expect(new Date(res.body.post.expiresAt).getTime()).toBeGreaterThan(Date.now());
    });

    it('returns 400 when a required field is missing', async () => {
        const token = await authUser();
        const res = await request(app)
            .post('/api/posts')
            .set('Authorization', `Bearer ${token}`)
            .send({ foodName: 'Pizza' });
        expect(res.status).toBe(400);
        expect(res.body.error).toMatch(/location/i);
    });
});

describe('GET /api/posts', () => {
    it('lists live posts with a computed confidence and status', async () => {
        const token = await authUser();
        await createPost(token);
        const res = await request(app).get('/api/posts');
        expect(res.status).toBe(200);
        expect(res.body.posts).toHaveLength(1);
        expect(res.body.posts[0].status).toBe('fresh');
        expect(res.body.posts[0].confidence).toBeGreaterThan(0.8);
    });

    it('excludes expired posts', async () => {
        const token = await authUser();
        const { body } = await createPost(token);
        await Post.updateOne({ _id: body.post._id }, { expiresAt: new Date(Date.now() - 1000) });
        const res = await request(app).get('/api/posts');
        expect(res.body.posts).toHaveLength(0);
    });

    it('orders by expiry, longest-lived first', async () => {
        const token = await authUser();
        const a = await createPost(token, { foodName: 'Soon' });
        const b = await createPost(token, { foodName: 'Later' });
        await Post.updateOne({ _id: a.body.post._id }, { expiresAt: new Date(Date.now() + 10 * 60000) });
        await Post.updateOne({ _id: b.body.post._id }, { expiresAt: new Date(Date.now() + 60 * 60000) });
        const res = await request(app).get('/api/posts');
        expect(res.body.posts.map((p: { foodName: string }) => p.foodName)).toEqual(['Later', 'Soon']);
    });
});

describe('POST /api/posts/:id/vote', () => {
    it('requires authentication', async () => {
        const token = await authUser();
        const { body } = await createPost(token);
        const res = await request(app).post(`/api/posts/${body.post._id}/vote`).send({ type: 'present' });
        expect(res.status).toBe(401);
    });

    it('a "gone" vote drops confidence below the fresh band', async () => {
        const token = await authUser();
        const { body } = await createPost(token);
        const res = await vote(token, body.post._id, 'gone');
        expect(res.status).toBe(200);
        expect(res.body.status).toBe('fading');
        expect(res.body.confidence).toBeLessThan(0.5);
    });

    it('a "present" vote keeps it fresh and confident', async () => {
        const token = await authUser();
        const { body } = await createPost(token);
        const res = await vote(token, body.post._id, 'present');
        expect(res.body.status).toBe('fresh');
        expect(res.body.confidence).toBeGreaterThan(0.9);
    });

    it('lets a user switch their vote to the other option', async () => {
        const token = await authUser();
        const { body } = await createPost(token);
        await vote(token, body.post._id, 'present').expect(200);
        const res = await vote(token, body.post._id, 'gone');
        expect(res.status).toBe(200);
        expect(res.body.tallies).toEqual({ present: 0, gone: 1 });
        expect(res.body.status).toBe('fading');

        const votes = (await Post.findById(body.post._id).select('+votes'))?.votes;
        expect(votes).toHaveLength(1);
        expect(votes?.[0]).toMatchObject({ type: 'gone' });
    });

    it('re-casting the same vote is a no-op', async () => {
        const token = await authUser();
        const { body } = await createPost(token);
        await vote(token, body.post._id, 'present').expect(200);
        const res = await vote(token, body.post._id, 'present');
        expect(res.status).toBe(200);
        expect(res.body.tallies).toEqual({ present: 1, gone: 0 });

        const votes = (await Post.findById(body.post._id).select('+votes'))?.votes;
        expect(votes).toHaveLength(1);
    });

    it('lets two different users each vote once', async () => {
        const author = await authUser();
        const other = await authUser();
        const { body } = await createPost(author);
        await vote(author, body.post._id, 'present').expect(200);
        await vote(other, body.post._id, 'gone').expect(200);
        expect((await Post.findById(body.post._id).select('+votes'))?.votes).toHaveLength(2);
    });

    it('returns 404 for a nonexistent post', async () => {
        const token = await authUser();
        const res = await vote(token, '0123456789abcdef01234567', 'present');
        expect(res.status).toBe(404);
    });

    it('returns 400 for an invalid vote type', async () => {
        const token = await authUser();
        const { body } = await createPost(token);
        const res = await vote(token, body.post._id, 'maybe');
        expect(res.status).toBe(400);
    });

    it('two "gone" votes kill the post and drop it from the feed', async () => {
        const u1 = await authUser();
        const u2 = await authUser();
        const { body } = await createPost(u1);
        await vote(u1, body.post._id, 'gone').expect(200);
        const res = await vote(u2, body.post._id, 'gone');
        expect(res.body.status).toBe('gone');

        const feed = await request(app).get('/api/posts');
        expect(feed.body.posts).toHaveLength(0);
    });
});

describe('GET /api/posts/upload-url', () => {
    it('requires authentication', async () => {
        const res = await request(app).get('/api/posts/upload-url');
        expect(res.status).toBe(401);
    });

    it('returns a signed url and key for an authed user', async () => {
        const token = await authUser();
        const res = await request(app).get('/api/posts/upload-url').set('Authorization', `Bearer ${token}`);
        expect(res.status).toBe(200);
        expect(res.body).toEqual({ url: 'https://signed.example/put', key: 'posts/abc.jpg' });
    });
});
