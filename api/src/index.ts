import express, { type Request, type Response } from 'express';
import cors from 'cors';
import config from './config/env.js'
import { connectDB } from './config/db.js';

const app = express();

app.use(cors());
app.use(express.json());

app.get('/api/health', (_req: Request, res: Response) => {
    res.json({ status: 'ok', uptime: process.uptime() });
});

async function start(): Promise<void> {
    try {
        await connectDB();
        app.listen(config.port, () => {
            console.log(`API listening on http://localhost:${config.port}`);
        });
    } catch (err) {
        console.error('Failed to start server:', err);
        process.exit(1);
    }
}

void start();
