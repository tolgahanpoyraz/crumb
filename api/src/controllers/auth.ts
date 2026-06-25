import { type Request, type Response } from 'express';
import jwt, { type JwtPayload } from 'jsonwebtoken';
import config from '../config/env.js'
import * as authService from '../services/auth.js';
import { requireFields } from '../middleware/errorHandler.js';
import { AppError } from '../errors.js';

export async function registerUser(req: Request, res: Response): Promise<void> {
    const { email, password } = req.body as { email?: string, password?: string };
    requireFields({ email, password }, ['email', 'password']);

    await authService.register(email!, password!);
    res.status(201).json({ message: 'Registered. Check your email to verify your account' });
}

export async function loginUser(req: Request, res: Response): Promise<void> {
    const { email, password } = req.body as { email?: string, password?: string };
    requireFields({ email, password }, ['email', 'password']);

    const user = await authService.login(email!, password!);
    const token = jwt.sign({ id: user._id }, config.jwtSecret, { expiresIn: '24h' });
    res.status(200).json({ token, user: { id: user._id, email: user.email } });
}

export async function verifyEmail(req: Request, res: Response): Promise<void> {
    const token = req.query.token as string | undefined;
    if (!token) {
        res.status(400).send('Missing verification token');
        return;
    }

    try {
        await authService.verifyEmailToken(token);
        res.status(200).send('<p>Email verified. You can now log in</p>');
    } catch (err) {
        if (err instanceof AppError) {
            res.status(err.status).send('<p>Verification failed. This email is invalid or expired</p>');
            return;
        }
        console.error('Verify failed:', err);
        res.status(500).send('Something went wrong');
    }
}

export async function getMe(req: Request, res: Response): Promise<void> {
    const { id } = req.auth as JwtPayload;
    const user = await authService.getUserById(id);
    res.status(200).json({ user: { id: user._id, email: user.email, verified: user.verified } });
}