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
import { Vote } from '../src/models/Vote.js';
import { sendVerificationEmail } from '../src/services/email.js';

const mockedVerifyEmail = vi.mocked(sendVerificationEmail);

const LOCATION = 'student-union';

let userCount = 0;

async function authUser(): Promise<string> {
    const email = `user${userCount++}@example.com`;
    const password = 'hunter2pw';
    const displayName = 'Testy';

    await request(app).post('/api/auth/register').send({ displayName, email, password });

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
        .send({ foodName: 'Bagels', type: 'snacks', location: LOCATION, ...body });
}

function vote(token: string, postId: string, type: string) {
    return request(app)
        .post(`/api/posts/${postId}/vote`)
        .set('Authorization', `Bearer ${token}`)
        .send({ type });
}

function deletePost(token: string, postId: string) {
    return request(app)
        .delete(`/api/posts/${postId}`)
        .set('Authorization', `Bearer ${token}`);
}

describe('POST /api/posts', () => {
    it('requires authentication', async () => {
        const res = await request(app).post('/api/posts').send({ foodName: 'Pizza', location: LOCATION });
        expect(res.status).toBe(401);
    });

    it('creates a fresh post with a future expiry', async () => {
        const token = await authUser();
        const res = await createPost(token, { foodName: 'Pizza', type: 'pizza', dietaryTags: ['vegetarian', 'halal'] });
        expect(res.status).toBe(201);
        expect(res.body.post).toMatchObject({
            foodName: 'Pizza',
            type: 'pizza',
            dietaryTags: ['vegetarian', 'halal'],
            location: { id: LOCATION },
            status: 'fresh',
        });
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

    it('rejects a whitespace-only foodName with 400', async () => {
        const token = await authUser();
        const res = await createPost(token, { foodName: '   ' });
        expect(res.status).toBe(400);
        expect(res.body.error).toMatch(/foodName/i);
    });

    it('rejects a malformed imageKey with 400', async () => {
        const token = await authUser();
        const res = await createPost(token, { imageKey: 'not-a-valid-key' });
        expect(res.status).toBe(400);
        expect(res.body.error).toMatch(/imageKey/i);
    });

    it('rejects an unknown location with 400', async () => {
        const token = await authUser();
        const res = await createPost(token, { location: 'not-a-real-place' });
        expect(res.status).toBe(400);
        expect(res.body.error).toMatch(/location/i);
    });

    it('stores an optional locationDetail', async () => {
        const token = await authUser();
        const res = await createPost(token, { locationDetail: '2nd floor lounge' });
        expect(res.status).toBe(201);
        expect(res.body.post.locationDetail).toBe('2nd floor lounge');
    });

    it('requires a type', async () => {
        const token = await authUser();
        const res = await request(app)
            .post('/api/posts')
            .set('Authorization', `Bearer ${token}`)
            .send({ foodName: 'Pizza', location: LOCATION });
        expect(res.status).toBe(400);
        expect(res.body.error).toMatch(/type/i);
    });

    it('rejects an unknown type with 400', async () => {
        const token = await authUser();
        const res = await createPost(token, { type: 'dessert' });
        expect(res.status).toBe(400);
        expect(res.body.error).toMatch(/type/i);
    });

    it('defaults dietaryTags to an empty array', async () => {
        const token = await authUser();
        const res = await createPost(token);
        expect(res.status).toBe(201);
        expect(res.body.post.dietaryTags).toEqual([]);
    });

    it('rejects an unknown dietary tag with 400', async () => {
        const token = await authUser();
        const res = await createPost(token, { dietaryTags: ['vegetarian', 'carnivore'] });
        expect(res.status).toBe(400);
        expect(res.body.error).toMatch(/dietary/i);
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

    it('resolves the location id to name and coordinates', async () => {
        const token = await authUser();
        await createPost(token);
        const res = await request(app).get('/api/posts');
        expect(res.body.posts[0].location).toMatchObject({
            id: LOCATION,
            name: expect.any(String),
            latitude: expect.any(Number),
            longitude: expect.any(Number),
        });
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

    it('rejects a second vote from the same user with 409', async () => {
        const token = await authUser();
        const { body } = await createPost(token);
        await vote(token, body.post._id, 'present').expect(200);
        const res = await vote(token, body.post._id, 'gone');
        expect(res.status).toBe(409);
    });

    it('lets two different users each vote once', async () => {
        const author = await authUser();
        const other = await authUser();
        const { body } = await createPost(author);
        await vote(author, body.post._id, 'present').expect(200);
        await vote(other, body.post._id, 'gone').expect(200);
        expect(await Vote.countDocuments({ post: body.post._id })).toBe(2);
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

    it('returns 400 for a malformed post id', async () => {
        const token = await authUser();
        const res = await vote(token, 'not-a-valid-id', 'present');
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

describe('DELETE /api/posts/:id', () => {
    it('requires authentication', async () => {
        const res = await request(app).delete('/api/posts/0123456789abcdef01234567');
        expect(res.status).toBe(401);
    });

    it('lets the author delete their own post', async () => {
        const token = await authUser();
        const { body } = await createPost(token);
        const res = await deletePost(token, body.post._id);
        expect(res.status).toBe(204);

        const feed = await request(app).get('/api/posts');
        expect(feed.body.posts).toHaveLength(0);
        expect(await Post.countDocuments({ _id: body.post._id })).toBe(0);
    });

    it("also removes the post's votes", async () => {
        const author = await authUser();
        const voter = await authUser();
        const { body } = await createPost(author);
        await vote(voter, body.post._id, 'present').expect(200);
        expect(await Vote.countDocuments({ post: body.post._id })).toBe(1);

        await deletePost(author, body.post._id).expect(204);
        expect(await Vote.countDocuments({ post: body.post._id })).toBe(0);
    });

    it("returns 403 when deleting another user's post", async () => {
        const author = await authUser();
        const other = await authUser();
        const { body } = await createPost(author);
        const res = await deletePost(other, body.post._id);
        expect(res.status).toBe(403);
        expect(await Post.countDocuments({ _id: body.post._id })).toBe(1);
    });

    it('returns 404 for a nonexistent post', async () => {
        const token = await authUser();
        const res = await deletePost(token, '0123456789abcdef01234567');
        expect(res.status).toBe(404);
    });
});