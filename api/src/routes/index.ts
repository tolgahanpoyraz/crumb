import { Router } from 'express';
import healthRouter from './health.js';
import authRouter from './auth.js';
import postsRouter from './posts.js';

const router = Router();

router.use('/health', healthRouter);
router.use('/auth', authRouter);
router.use('/posts', postsRouter);

export default router;
