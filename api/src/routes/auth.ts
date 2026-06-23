import { Router } from 'express';
import config from '../config/env.js'
import jwt from 'jsonwebtoken';

const router = Router();

router.post('/login', (_req, res) => { // PLACEHOLDER, CHANGE LATER
    const payload = { user: 'test' };
    const token = jwt.sign(payload, config.jwtSecret, {
        expiresIn: "1h",
    })
    res.json({ token })
})

router.post('/register', (_req, res) => {
    // TODO
})

export default router;