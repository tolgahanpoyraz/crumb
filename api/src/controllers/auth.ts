import { type Request, type Response } from 'express';
import jwt, { type JwtPayload } from 'jsonwebtoken';
import config from '../config/env.js'
import * as authService from '../services/auth.js';
import { requireFields } from '../middleware/errorHandler.js';
import { AppError } from '../errors.js';

function signToken(userId: unknown): string {
    return jwt.sign({ id: userId }, config.jwtSecret, { expiresIn: '24h' });
}

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
    const token = signToken(user._id);
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

export async function resendVerification(req: Request, res: Response): Promise<void> {
    const { email } = req.body as { email?: string };
    requireFields({ email }, ['email']);

    await authService.resendVerification(email!);
    res.status(200).json({ message: 'If that account exists and is unverified, a verification email has been sent.' });
}

export async function changePassword(req: Request, res: Response): Promise<void> {
    const { id } = req.auth as JwtPayload;
    const { currentPassword, newPassword } = req.body as { currentPassword?: string; newPassword?: string };
    requireFields({ currentPassword, newPassword }, ['currentPassword', 'newPassword']);

    const user = await authService.changePassword(id, currentPassword!, newPassword!);
    const token = signToken(user._id);
    res.status(200).json({ token, message: 'Password changed successfully.' });
}

export async function forgotPassword(req: Request, res: Response): Promise<void> {
    const { email } = req.body as { email?: string };
    requireFields({ email }, ['email']);

    await authService.forgotPassword(email!);
    res.status(200).json({ message: 'If that account exists, a password reset email has been sent.' });
}

export async function resetPassword(req: Request, res: Response): Promise<void> {
    const { token, password } = req.body as { token?: string; password?: string };
    requireFields({ token, password }, ['token', 'password']);

    await authService.resetPassword(token!, password!);
    res.status(200).json({ message: 'Password has been reset. You can now log in.' });
}