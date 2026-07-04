import mongoose from 'mongoose';
import config from './env.js';
import logger from './logger.js';

export async function connectDB(): Promise<void> {
    try {
        await mongoose.connect(config.mongoUri);
        logger.info('Connected to MongoDB');
    } catch (err) {
        logger.error({ err }, 'MongoDB connection failed');
        process.exit(1);
    }
}