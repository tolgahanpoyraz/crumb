import { Router } from 'express';
import { registerUser, loginUser, verifyEmail, getMe } from '../controllers/auth.js';
import { authenticate } from '../middleware/authenticate.js';

const router = Router();

router.post('/login', loginUser);
router.post('/register', registerUser);
router.get('/verify', verifyEmail);
router.get('/me', authenticate, getMe);

export default router;