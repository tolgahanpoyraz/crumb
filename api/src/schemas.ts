import { z } from 'zod';

const name = z.string().trim().min(1, 'Name is required').max(100);
const email = z.string().trim().toLowerCase().pipe(z.email('Invalid email address'));
const password = z.string().min(8, 'Password must be at least 8 characters').max(200);

export const registerSchema = z.object({
    firstName: name,
    lastName: name,
    email,
    password,
});

export const loginSchema = z.object({
    email,
    password: z.string().min(1, 'Password is required'),
});

export const emailOnlySchema = z.object({
    email,
});

export const resetPasswordSchema = z.object({
    token: z.string().min(1, 'Token is required'),
    password,
});

export const changePasswordSchema = z.object({
    currentPassword: z.string().min(1, 'Current password is required'),
    newPassword: password,
});

export const createPostSchema = z.object({
    foodName: z.string().trim().min(1, 'foodName is required').max(100),
    location: z.string().trim().min(1, 'location is required').max(100),
    badges: z.array(z.string().trim().min(1).max(30)).max(10).optional().default([]),
    imageKey: z.string().regex(/^posts\/[a-f0-9-]+\.jpg$/, 'Invalid imageKey').optional(),
});

export const voteSchema = z.object({
    type: z.enum(['present', 'gone']),
});

export type RegisterInput = z.infer<typeof registerSchema>;
export type LoginInput = z.infer<typeof loginSchema>;
export type EmailOnlyInput = z.infer<typeof emailOnlySchema>;
export type ResetPasswordInput = z.infer<typeof resetPasswordSchema>;
export type ChangePasswordInput = z.infer<typeof changePasswordSchema>;
export type CreatePostInput = z.infer<typeof createPostSchema>;
export type VoteInput = z.infer<typeof voteSchema>;