import { Router } from 'express';
import { getLocations } from '../controllers/locations.js';

const router = Router();

router.get('/', getLocations);

export default router;