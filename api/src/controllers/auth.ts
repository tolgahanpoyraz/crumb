import { type Request, type Response } from 'express';
import { type HydratedDocument } from 'mongoose';
import jwt, { type JwtPayload } from 'jsonwebtoken';
import config from '../config/env.js'
import * as authService from '../services/auth.js';
import * as uploadService from '../services/uploads.js';
import { type IUser } from '../models/User.js';
import logger from '../config/logger.js';
import { AppError } from '../errors.js';
import { type RegisterInput, type LoginInput, type EmailOnlyInput, type ResetPasswordInput, type ChangePasswordInput } from '../schemas.js';

function signToken(userId: unknown): string {
    return jwt.sign({ id: userId }, config.jwtSecret, { expiresIn: '24h' });
}

function publicUser(user: HydratedDocument<IUser>) {
    return {
        id: user._id,
        displayName: user.displayName,
        email: user.email,
        avatarKey: user.avatarKey,
    };
}

export async function registerUser(req: Request, res: Response): Promise<void> {
    const { displayName, email, password } = req.body as RegisterInput;

    await authService.register({ displayName, email, password });
    res.status(201).json({ message: 'Registered. Check your email to verify your account' });
}

export async function loginUser(req: Request, res: Response): Promise<void> {
    const { email, password } = req.body as LoginInput;

    const user = await authService.login(email, password);
    const token = signToken(user._id);
    res.status(200).json({ token, user: publicUser(user) });
}

// Verification links are opened straight from an email client, so this always
// lands the browser on a web app page rather than returning JSON or raw HTML.
function verifyErrorRedirect(reason: 'invalid' | 'server'): string {
    const url = new URL('/verify-email', config.appUrl);
    url.searchParams.set('error', reason);
    return url.toString();
}

export async function verifyEmail(req: Request, res: Response): Promise<void> {
    const token = req.query.token as string | undefined;
    if (!token) {
        res.redirect(302, verifyErrorRedirect('invalid'));
        return;
    }

    try {
        const user = await authService.verifyEmailToken(token);
        const url = new URL('/email-verified', config.appUrl);
        url.searchParams.set('name', user.displayName);
        res.redirect(302, url.toString());
    } catch (err) {
        if (err instanceof AppError) {
            res.redirect(302, verifyErrorRedirect('invalid'));
            return;
        }
        logger.error({ err }, 'Verify failed');
        res.redirect(302, verifyErrorRedirect('server'));
    }
}

export async function getMe(req: Request, res: Response): Promise<void> {
    const { id } = req.auth as JwtPayload;
    const user = await authService.getUserById(id);
    res.status(200).json({ user: { ...publicUser(user), verified: user.verified } });
}

export async function getAvatarUploadUrl(req: Request, res: Response): Promise<void> {
    const { id } = req.auth as JwtPayload;
    const result = await uploadService.createAvatarUploadUrl(id);
    res.status(200).json(result);
}

export async function setAvatar(req: Request, res: Response): Promise<void> {
    const { id } = req.auth as JwtPayload;
    const user = await authService.setAvatar(id);
    res.status(200).json({ user: publicUser(user) });
}

export async function resendVerification(req: Request, res: Response): Promise<void> {
    const { email } = req.body as EmailOnlyInput;

    await authService.resendVerification(email);
    res.status(200).json({ message: 'If that account exists and is unverified, a verification email has been sent.' });
}

export async function changePassword(req: Request, res: Response): Promise<void> {
    const { id } = req.auth as JwtPayload;
    const { currentPassword, newPassword } = req.body as ChangePasswordInput;

    const user = await authService.changePassword(id, currentPassword, newPassword);
    const token = signToken(user._id);
    res.status(200).json({ token, message: 'Password changed successfully.' });
}

export async function forgotPassword(req: Request, res: Response): Promise<void> {
    const { email } = req.body as EmailOnlyInput;

    await authService.forgotPassword(email);
    res.status(200).json({ message: 'If that account exists, a password reset email has been sent.' });
}

export async function resetPassword(req: Request, res: Response): Promise<void> {
    const { token, password } = req.body as ResetPasswordInput;

    await authService.resetPassword(token, password);
    res.status(200).json({ message: 'Password has been reset. You can now log in.' });
}