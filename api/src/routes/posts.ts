import { Router } from 'express';
import { createPost, getFeed, getUploadUrl, votePost } from '../controllers/posts.js';
import { authenticate } from '../middleware/authenticate.js';
import { validate } from '../middleware/validate.js';
import { createPostSchema, voteSchema } from '../schemas.js';

const router = Router();

router.get('/', getFeed);
router.get('/upload-url', authenticate, getUploadUrl);
router.post('/', authenticate, validate(createPostSchema), createPost);
router.post('/:id/vote', authenticate, validate(voteSchema), votePost);

export default router;