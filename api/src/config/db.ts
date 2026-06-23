import mongoose from 'mongoose';
import config from './env.js';

export async function connectDB(): Promise<void> {
    try {
        await mongoose.connect(config.mongoUri);
        console.log('Connected to MongoDB');
    } catch (err) {
        console.error('MongoDB connection failed:', err);
        process.exit(1);
    }
}