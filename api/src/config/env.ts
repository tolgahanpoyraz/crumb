import dotenv from 'dotenv';
dotenv.config();

interface Config {
    port: number;
    mongoUri: string;
    jwtSecret: string;
}

const config: Config = {
    port: Number(process.env.PORT ?? 5001),
    mongoUri: process.env.MONGO_URI ?? 'mongodb://127.0.0.1:27017/bigproject',
    jwtSecret: process.env.JWT_SECRET ?? 'dev'
}

export default config;