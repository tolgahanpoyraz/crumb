import { Router } from 'express';
import { registerUser, loginUser, verifyEmail, getMe, resendVerification, forgotPassword, resetPassword, changePassword } from '../controllers/auth.js';
import { authenticate } from '../middleware/authenticate.js';
import { validate } from '../middleware/validate.js';
import { registerSchema, loginSchema, emailOnlySchema, resetPasswordSchema, changePasswordSchema } from '../schemas.js';

const router = Router();

router.post('/login', validate(loginSchema), loginUser);
router.post('/register', validate(registerSchema), registerUser);
router.get('/verify', verifyEmail);
router.post('/resend-verification', validate(emailOnlySchema), resendVerification);
router.post('/forgot-password', validate(emailOnlySchema), forgotPassword);
router.post('/reset-password', validate(resetPasswordSchema), resetPassword);
router.post('/change-password', authenticate, validate(changePasswordSchema), changePassword);
router.get('/me', authenticate, getMe);

export default router;