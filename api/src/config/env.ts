import dotenv from 'dotenv';
dotenv.config();

interface Config {
    port: number;
    mongoUri: string;
    jwtSecret: string;
}

const jwtSecret = process.env.JWT_SECRET;
if (!jwtSecret) {
    throw new Error('JWT_SECRET is not set. Add it to api/.env (see .env.example).');
}

const config: Config = {
    port: Number(process.env.PORT ?? 5001),
    mongoUri: process.env.MONGO_URI ?? 'mongodb://127.0.0.1:27017/bigproject',
    jwtSecret,
}

export default config;