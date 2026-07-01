import { Router } from 'express';
import { createPost, getFeed, getUploadUrl, votePost } from '../controllers/posts.js';
import { authenticate } from '../middleware/authenticate.js';

const router = Router();

router.get('/', getFeed);
router.get('/upload-url', authenticate, getUploadUrl);
router.post('/', authenticate, createPost);
router.post('/:id/vote', authenticate, votePost);

export default router;