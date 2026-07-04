import config from './config/env.js';
import { connectDB } from './config/db.js';
import app from './app.js';
import logger from './config/logger.js';

async function start(): Promise<void> {
    try {
        await connectDB();
        app.listen(config.port, () => {
            logger.info(`API listening on http://localhost:${config.port}`);
        });
    } catch (err) {
        logger.error({ err }, 'Failed to start server');
        process.exit(1);
    }
}

void start();