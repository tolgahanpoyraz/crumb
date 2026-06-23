import { type Request, type Response, type NextFunction } from "express";
import jwt from 'jsonwebtoken';
import config from '../config/env.js'

export function authenticate(req: Request, res: Response, next: NextFunction): void {
    const header = req.headers.authorization;
    if (!header?.startsWith('Bearer ')) {
        res.status(401).json({ error: 'Invalid token' });
        return;
    }

    try {
        const payload = jwt.verify(header.slice(7), config.jwtSecret);
        req.user = payload;
        next();
    } catch {
        res.status(401).json({ error: 'Invalid or expired token' });
        return;
    }
}