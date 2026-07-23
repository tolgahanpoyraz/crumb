import { Router } from 'express';
import { getLeaderboard } from '../controllers/users.js';
import { authenticate } from '../middleware/authenticate.js';

const router = Router();

router.get('/leaderboard', authenticate, getLeaderboard);

export default router;
