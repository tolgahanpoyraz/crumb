import { describe, it, expect, vi } from 'vitest';
import request from 'supertest';

vi.mock('../src/services/email.js', () => ({
    sendVerificationEmail: vi.fn().mockResolvedValue(undefined),
    sendPasswordResetEmail: vi.fn().mockResolvedValue(undefined),
}));

import app from '../src/app.js';
import { User } from '../src/models/User.js';
import { sendVerificationEmail, sendPasswordResetEmail } from '../src/services/email.js';

const mockedVerifyEmail = vi.mocked(sendVerificationEmail);
const mockedResetEmail = vi.mocked(sendPasswordResetEmail);

const EMAIL = 'user@example.com';
const PASSWORD = 'hunter2pw';
const NEW_PASSWORD = 'newpass123';
const FIRST_NAME = 'Test';
const LAST_NAME = 'User';

function register(email = EMAIL, password = PASSWORD, firstName = FIRST_NAME, lastName = LAST_NAME) {
    return request(app).post('/api/auth/register').send({ firstName, lastName, email, password });
}

function login(email = EMAIL, password = PASSWORD) {
    return request(app).post('/api/auth/login').send({ email, password });
}

function lastTokenFrom(mock: typeof mockedVerifyEmail): string {
    const { calls } = mock.mock;
    return calls[calls.length - 1][1] as string;
}

async function registerAndVerify(email = EMAIL, password = PASSWORD) {
    await register(email, password);
    await request(app).get('/api/auth/verify').query({ token: lastTokenFrom(mockedVerifyEmail) });
}

async function registerVerifyLogin(email = EMAIL, password = PASSWORD) {
    await registerAndVerify(email, password);
    const res = await login(email, password);
    return { token: res.body.token as string, id: res.body.user.id as string };
}

describe('GET /api/health', () => {
    it('reports ok', async () => {
        const res = await request(app).get('/api/health');
        expect(res.status).toBe(200);
        expect(res.body.status).toBe('ok');
        expect(typeof res.body.uptime).toBe('number');
    });
});

describe('POST /api/auth/register', () => {
    it('creates an unverified user and sends a verification email', async () => {
        const res = await register();
        expect(res.status).toBe(201);
        const user = await User.findOne({ email: EMAIL });
        expect(user?.verified).toBe(false);
        expect(user?.firstName).toBe(FIRST_NAME);
        expect(user?.lastName).toBe(LAST_NAME);
        expect(mockedVerifyEmail).toHaveBeenCalledOnce();
        expect(mockedVerifyEmail.mock.calls[0][0]).toBe(EMAIL);
    });

    it('rejects a duplicate email with 409', async () => {
        await register();
        const res = await register();
        expect(res.status).toBe(409);
        expect(res.body.error).toMatch(/already in use/i);
    });

    it('returns 400 when a field is missing', async () => {
        const res = await request(app).post('/api/auth/register').send({ email: EMAIL });
        expect(res.status).toBe(400);
        expect(res.body.error).toMatch(/password|firstName|lastName/i);
    });

    it('rejects a password shorter than 8 characters with 400', async () => {
        const res = await register(EMAIL, 'short');
        expect(res.status).toBe(400);
        expect(res.body.error).toMatch(/password/i);
    });

    it('rejects a malformed email with 400', async () => {
        const res = await register('not-an-email', PASSWORD);
        expect(res.status).toBe(400);
        expect(res.body.error).toMatch(/email/i);
    });
});

describe('POST /api/auth/login', () => {
    it('rejects an unverified account with 403', async () => {
        await register();
        const res = await login();
        expect(res.status).toBe(403);
        expect(res.body.error).toMatch(/not verified/i);
    });

    it('returns a token once verified', async () => {
        await registerAndVerify();
        const res = await login();
        expect(res.status).toBe(200);
        expect(res.body.token).toBeTruthy();
        expect(res.body.user).toMatchObject({
            email: EMAIL,
            firstName: FIRST_NAME,
            lastName: LAST_NAME,
        });
    });

    it('returns 401 on wrong password', async () => {
        await registerAndVerify();
        const res = await login(EMAIL, 'wrongpass');
        expect(res.status).toBe(401);
    });

    it('returns 401 on unknown email', async () => {
        const res = await login('nobody@example.com', PASSWORD);
        expect(res.status).toBe(401);
    });
});

describe('GET /api/auth/verify', () => {
    it('verifies the account', async () => {
        await register();
        const res = await request(app).get('/api/auth/verify').query({ token: lastTokenFrom(mockedVerifyEmail) });
        expect(res.status).toBe(200);
        const user = await User.findOne({ email: EMAIL });
        expect(user?.verified).toBe(true);
    });

    it('rejects an invalid token with 400', async () => {
        const res = await request(app).get('/api/auth/verify').query({ token: 'bogus' });
        expect(res.status).toBe(400);
    });

    it('consumes the token so a second use fails', async () => {
        await register();
        const token = lastTokenFrom(mockedVerifyEmail);
        await request(app).get('/api/auth/verify').query({ token }).expect(200);
        const res = await request(app).get('/api/auth/verify').query({ token });
        expect(res.status).toBe(400);
    });
});

describe('POST /api/auth/resend-verification', () => {
    it('sends mail for an unverified account', async () => {
        await register();
        mockedVerifyEmail.mockClear();
        const res = await request(app).post('/api/auth/resend-verification').send({ email: EMAIL });
        expect(res.status).toBe(200);
        expect(mockedVerifyEmail).toHaveBeenCalledOnce();
    });

    it('returns 200 but sends nothing for an unknown email', async () => {
        const res = await request(app).post('/api/auth/resend-verification').send({ email: 'nobody@example.com' });
        expect(res.status).toBe(200);
        expect(mockedVerifyEmail).not.toHaveBeenCalled();
    });

    it('returns 200 but sends nothing once already verified', async () => {
        await registerAndVerify();
        mockedVerifyEmail.mockClear();
        const res = await request(app).post('/api/auth/resend-verification').send({ email: EMAIL });
        expect(res.status).toBe(200);
        expect(mockedVerifyEmail).not.toHaveBeenCalled();
    });
});

describe('POST /api/auth/forgot-password', () => {
    it('sends a reset email for a known account', async () => {
        await registerAndVerify();
        const res = await request(app).post('/api/auth/forgot-password').send({ email: EMAIL });
        expect(res.status).toBe(200);
        expect(mockedResetEmail).toHaveBeenCalledOnce();
    });

    it('returns 200 but sends nothing for an unknown email', async () => {
        const res = await request(app).post('/api/auth/forgot-password').send({ email: 'nobody@example.com' });
        expect(res.status).toBe(200);
        expect(mockedResetEmail).not.toHaveBeenCalled();
    });
});

describe('POST /api/auth/reset-password', () => {
    it('sets a new password that works and rejects the old one', async () => {
        await registerAndVerify();
        await request(app).post('/api/auth/forgot-password').send({ email: EMAIL });
        const token = lastTokenFrom(mockedResetEmail);

        await request(app).post('/api/auth/reset-password').send({ token, password: NEW_PASSWORD }).expect(200);
        await login(EMAIL, PASSWORD).expect(401);
        await login(EMAIL, NEW_PASSWORD).expect(200);
    });

    it('rejects an invalid token with 400', async () => {
        const res = await request(app).post('/api/auth/reset-password').send({ token: 'bogus', password: NEW_PASSWORD });
        expect(res.status).toBe(400);
    });

    it('rejects a short new password with 400', async () => {
        const res = await request(app).post('/api/auth/reset-password').send({ token: 'bogus', password: 'short' });
        expect(res.status).toBe(400);
        expect(res.body.error).toMatch(/password/i);
    });
});

describe('POST /api/auth/change-password', () => {
    it('requires authentication', async () => {
        const res = await request(app)
            .post('/api/auth/change-password')
            .send({ currentPassword: PASSWORD, newPassword: NEW_PASSWORD });
        expect(res.status).toBe(401);
    });

    it('rejects a wrong current password with 401', async () => {
        const { token } = await registerVerifyLogin();
        const res = await request(app)
            .post('/api/auth/change-password')
            .set('Authorization', `Bearer ${token}`)
            .send({ currentPassword: 'wrongpass', newPassword: NEW_PASSWORD });
        expect(res.status).toBe(401);
    });

    it('changes the password and returns a working new token', async () => {
        const { token } = await registerVerifyLogin();
        const res = await request(app)
            .post('/api/auth/change-password')
            .set('Authorization', `Bearer ${token}`)
            .send({ currentPassword: PASSWORD, newPassword: NEW_PASSWORD });
        expect(res.status).toBe(200);
        expect(res.body.token).toBeTruthy();

        await request(app).get('/api/auth/me').set('Authorization', `Bearer ${res.body.token}`).expect(200);
        await login(EMAIL, NEW_PASSWORD).expect(200);
    });
});

describe('GET /api/auth/me', () => {
    it('returns the current user with a valid token', async () => {
        const { token } = await registerVerifyLogin();
        const res = await request(app).get('/api/auth/me').set('Authorization', `Bearer ${token}`);
        expect(res.status).toBe(200);
        expect(res.body.user).toMatchObject({
            email: EMAIL,
            verified: true,
            firstName: FIRST_NAME,
            lastName: LAST_NAME,
        });
    });

    it('returns 401 without a token', async () => {
        const res = await request(app).get('/api/auth/me');
        expect(res.status).toBe(401);
    });

    it('returns 401 with a malformed token', async () => {
        const res = await request(app).get('/api/auth/me').set('Authorization', 'Bearer not-a-jwt');
        expect(res.status).toBe(401);
    });

    it('rejects a token issued before the password changed', async () => {
        const { token, id } = await registerVerifyLogin();
        await request(app).get('/api/auth/me').set('Authorization', `Bearer ${token}`).expect(200);

        await User.updateOne({ _id: id }, { passwordChangedAt: new Date(Date.now() + 10_000) });
        await request(app).get('/api/auth/me').set('Authorization', `Bearer ${token}`).expect(401);
    });
});