import config from './config/env.js';
import { connectDB } from './config/db.js';
import app from './app.js';

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