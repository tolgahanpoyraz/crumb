import crypto from 'crypto';
import { User } from '../models/User.js';
import { sendVerificationEmail } from './email.js';
import { AppError } from '../errors.js';

const VERIFICATION_TTL = 1000 * 60 * 60 * 24;   // 24 hours

function hashToken(raw: string): string {
    return crypto.createHash('sha256').update(raw).digest('hex')
}

export async function register(email: string, password: string) {
    const existing = await User.findOne({ email });
    if (existing) {
        throw new AppError(409, 'Email already in use');
    }

    const user = await User.create({ email, password })

    const rawToken = crypto.randomBytes(32).toString('hex');
    user.verificationToken = hashToken(rawToken);
    user.verificationTokenExpires = new Date(Date.now() + VERIFICATION_TTL);
    await user.save();

    await sendVerificationEmail(user.email, rawToken);
    return user;
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

export async function getUserById(id: string) {
    const user = await User.findById(id);
    if (!user) {
        throw new AppError(404, 'User not found');
    }
    return user;
}