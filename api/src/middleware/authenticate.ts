import { type Request, type Response, type NextFunction } from "express";
import jwt, { type JwtPayload } from 'jsonwebtoken';
import config from '../config/env.js'
import { User } from '../models/User.js';

export async function authenticate(req: Request, res: Response, next: NextFunction): Promise<void> {
    const header = req.headers.authorization;
    if (!header?.startsWith('Bearer ')) {
        res.status(401).json({ error: 'Invalid token' });
        return;
    }

    let payload: JwtPayload;
    try {
        payload = jwt.verify(header.slice(7), config.jwtSecret) as JwtPayload;
    } catch {
        res.status(401).json({ error: 'Invalid or expired token' });
        return;
    }

    const user = await User.findById(payload.id).select('+passwordChangedAt');
    if (!user) {
        res.status(401).json({ error: 'Invalid or expired token' });
        return;
    }

    if (payload.iat && user.passwordChangedAfter(payload.iat)) {
        res.status(401).json({ error: 'Token no longer valid, please log in again' });
        return;
    }

    req.auth = payload;
    next();
}