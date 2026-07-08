import { z } from 'zod';
import { LOCATION_IDS } from './locations.js';
import { POST_TYPES, DIETARY_TAGS, VOTE_TYPES } from './models/Post.js';

const name = z.string().trim().min(1, 'Name is required').max(100);
const email = z.string().trim().toLowerCase().pipe(z.email('Invalid email address'));
const password = z.string().min(8, 'Password must be at least 8 characters').max(200);

export const registerSchema = z.object({
    displayName: name,
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
    type: z.enum(POST_TYPES, { message: 'Invalid type' }),
    dietaryTags: z.array(z.enum(DIETARY_TAGS, { message: 'Invalid dietary tag' })).max(DIETARY_TAGS.length).optional().default([]),
    location: z.enum(LOCATION_IDS, { message: 'Invalid location' }),
    locationDetail: z.string().trim().max(256).optional(),
    imageKey: z.string().regex(/^posts\/[a-f0-9-]+\.jpg$/, 'Invalid imageKey').optional(),
});

export const voteSchema = z.object({
    type: z.enum(VOTE_TYPES),
});

export type RegisterInput = z.infer<typeof registerSchema>;
export type LoginInput = z.infer<typeof loginSchema>;
export type EmailOnlyInput = z.infer<typeof emailOnlySchema>;
export type ResetPasswordInput = z.infer<typeof resetPasswordSchema>;
export type ChangePasswordInput = z.infer<typeof changePasswordSchema>;
export type CreatePostInput = z.infer<typeof createPostSchema>;
export type VoteInput = z.infer<typeof voteSchema>;