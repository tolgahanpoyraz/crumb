import { Router } from 'express';
import healthRouter from './health.js';
import authRouter from './auth.js';
import postsRouter from './posts.js';
import locationsRouter from './locations.js';

const router = Router();

router.use('/health', healthRouter);
router.use('/auth', authRouter);
router.use('/posts', postsRouter);
router.use('/locations', locationsRouter);

export default router;
