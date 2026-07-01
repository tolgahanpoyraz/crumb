import { type Request, type Response } from 'express';
import { type JwtPayload } from 'jsonwebtoken';
import * as postService from '../services/posts.js';
import * as uploadService from '../services/uploads.js';
import { type VoteType } from '../models/Post.js';
import { requireFields } from '../middleware/errorHandler.js';
import { AppError } from '../errors.js';

export async function createPost(req: Request, res: Response): Promise<void> {
    const { id } = req.auth as JwtPayload;
    const { foodName, location, badges, imageKey } = req.body as {
        foodName?: string; location?: string; badges?: string[]; imageKey?: string;
    };
    requireFields({ foodName, location }, ['foodName', 'location']);

    const post = await postService.createPost(id, {
        foodName: foodName!,
        location: location!,
        badges: badges ?? [],
        imageKey,
    });
    res.status(201).json({ post });
}

export async function getFeed(_req: Request, res: Response): Promise<void> {
    const posts = await postService.listFeed();
    res.status(200).json({ posts });
}

export async function getUploadUrl(_req: Request, res: Response): Promise<void> {
    const result = await uploadService.createUploadUrl();
    res.status(200).json(result);
}

export async function votePost(req: Request, res: Response): Promise<void> {
    const { id: userId } = req.auth as JwtPayload;
    const { id: postId } = req.params as { id: string };
    const { type } = req.body as { type?: VoteType };
    requireFields({ type }, ['type']);
    if (type !== 'present' && type !== 'gone') {
        throw new AppError(400, "type must be 'present' or 'gone'");
    }

    const result = await postService.vote(postId, userId, type);
    res.status(200).json(result);
}