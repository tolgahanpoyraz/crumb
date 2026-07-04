import { type Request, type Response, type NextFunction } from "express";
import { AppError } from "../errors.js";
import logger from "../config/logger.js";

interface MongoLikeError {
    name?: string;
    code?: number;
    errors?: Record<string, { message: string }>;
}

export function errorHandler(err: unknown, _req: Request, res: Response, _next: NextFunction): void {
    if (err instanceof AppError) {
        res.status(err.status).json({ error: err.message });
        return;
    }

    const e = err as MongoLikeError;

    if (e.name === 'ValidationError') {
        const detail = Object.values(e.errors ?? {}).map((v) => v.message).join('; ');
        res.status(400).json({ error: detail || 'Validation failed' });
        return;
    }

    if (e.name === 'CastError') {
        res.status(400).json({ error: 'Invalid identifier' });
        return;
    }

    if (e.code === 11000) {
        res.status(409).json({ error: 'Resource already exists' });
        return;
    }

    logger.error({ err }, 'Unhandled error');
    res.status(500).json({ error: 'Internal server error' });
}