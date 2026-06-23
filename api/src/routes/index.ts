import { Router } from 'express';
import healthRouter from './health.js';
import authRouter from './auth.js';
import { authenticate } from '../middleware/authenticate.js';

const router = Router();

router.use('/health', healthRouter);
router.use('/auth', authRouter);

router.get('/protected', authenticate, (req, res) => { // TEST ENDPOINT, DELETE LATER
    res.json({ user: req.user })
})

export default router;