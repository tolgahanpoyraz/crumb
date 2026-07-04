import { Router, type Request, type Response } from 'express';
import mongoose from 'mongoose';

const router = Router();

router.get('/', (_req: Request, res: Response) => {
    const dbUp = mongoose.connection.readyState === 1;
    res.status(dbUp ? 200 : 503).json({
        status: dbUp ? 'ok' : 'degraded',
        uptime: process.uptime(),
        db: dbUp ? 'connected' : 'disconnected',
    });
})

export default router;