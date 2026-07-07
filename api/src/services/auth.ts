import crypto from 'crypto';
import { type HydratedDocument } from 'mongoose';
import { User, type IUser } from '../models/User.js';
import { sendVerificationEmail, sendPasswordResetEmail } from './email.js';
import logger from '../config/logger.js';
import { AppError } from '../errors.js';

const VERIFICATION_TTL = 1000 * 60 * 60 * 24;   // 24 hours
const RESET_TTL = 1000 * 60 * 60;               // 1 hour 

function hashToken(raw: string): string {
    return crypto.createHash('sha256').update(raw).digest('hex')
}

async function issueVerificationToken(user: HydratedDocument<IUser>): Promise<void> {
    const rawToken = crypto.randomBytes(32).toString('hex');
    user.verificationToken = hashToken(rawToken);
    user.verificationTokenExpires = new Date(Date.now() + VERIFICATION_TTL);
    await user.save();
    try {
        await sendVerificationEmail(user.email, rawToken);
    } catch (err) {
        logger.error({ err, email: user.email }, 'Failed to send verification email');
    }
}

async function issuePasswordResetToken(user: HydratedDocument<IUser>): Promise<void> {
    const rawToken = crypto.randomBytes(32).toString('hex');
    user.resetToken = hashToken(rawToken);
    user.resetTokenExpires = new Date(Date.now() + RESET_TTL);
    await user.save();
    try {
        await sendPasswordResetEmail(user.email, rawToken);
    } catch (err) {
        logger.error({ err, email: user.email }, 'Failed to send password reset email');
    }
}

export async function register(displayName: string, email: string, password: string) {
    const existing = await User.findOne({ email });
    if (existing) {
        throw new AppError(409, 'Email already in use');
    }

    const user = await User.create({ displayName, email, password })

    await issueVerificationToken(user);
    return user;
}

export async function resendVerification(email: string): Promise<void> {
    const user = await User.findOne({ email });

    if (user && !user.verified) {
        await issueVerificationToken(user);
    }
}

export async function login(email: string, password: string) {
    const user = await User.findOne({ email }).select('+password')
    if (!user) {
        throw new AppError(401, 'Invalid credentials');
    }

    const ok = await user.comparePassword(password);
    if (!ok) {
        throw new AppError(401, 'Invalid credentials');
    }

    if (!user.verified) {
        throw new AppError(403, 'Email not verified');
    }

    return user;
}

export async function verifyEmailToken(rawToken: string) {
    const user = await User.findOne({
        verificationToken: hashToken(rawToken),
        verificationTokenExpires: { $gt: new Date() },
    });

    if (!user) {
        throw new AppError(400, 'Invalid or expired verification token');
    }

    user.verified = true;
    user.verificationToken = undefined;
    user.verificationTokenExpires = undefined;
    await user.save();
    return user;
}

export async function resetPassword(rawToken: string, newPassword: string): Promise<void> {
    const user = await User.findOne({
        resetToken: hashToken(rawToken),
        resetTokenExpires: { $gt: new Date() },
    });

    if (!user) {
        throw new AppError(400, 'Invalid or expired reset token');
    }

    user.password = newPassword;
    user.resetToken = undefined;
    user.resetTokenExpires = undefined;
    await user.save();
}

export async function changePassword(userId: string, currentPassword: string, newPassword: string) {
    const user = await User.findById(userId).select('+password');
    if (!user) {
        throw new AppError(404, 'User not found');
    }

    const ok = await user.comparePassword(currentPassword);
    if (!ok) {
        throw new AppError(401, 'Current password is incorrect');
    }

    user.password = newPassword;
    await user.save();
    return user;
}

export async function getUserById(id: string) {
    const user = await User.findById(id);
    if (!user) {
        throw new AppError(404, 'User not found');
    }
    return user;
}

export async function forgotPassword(email: string): Promise<void> {
    const user = await User.findOne({ email });
    if (user) {
        await issuePasswordResetToken(user);
    }
}