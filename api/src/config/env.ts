import dotenv from 'dotenv';
dotenv.config();

interface Config {
    port: number;
    mongoUri: string;
    jwtSecret: string;
    sendgridApiKey: string;
    sendgridFromEmail: string;
    appUrl: string;
    webAppUrl: string;
    corsOrigins: string[];
    awsRegion: string;
    s3Bucket: string;
}

function required(key: string) {
    const value = process.env[key];
    if (!value) {
        throw new Error(`Missing required env var: ${key}`);
    }
    return value;
}

const config: Config = {
    port: Number(process.env.PORT ?? 5001),
    mongoUri: process.env.MONGO_URI ?? 'mongodb://127.0.0.1:27017/bigproject',
    jwtSecret: required('JWT_SECRET'),
    sendgridApiKey: required('SENDGRID_API_KEY'),
    sendgridFromEmail: required('SENDGRID_FROM_EMAIL'),
    appUrl: process.env.APP_URL ?? 'http://localhost:5001',
    webAppUrl: process.env.WEB_APP_URL ?? 'http://localhost:5173',
    corsOrigins: (process.env.CORS_ORIGINS ?? '').split(',').map((s) => s.trim()).filter(Boolean),
    awsRegion: process.env.AWS_REGION ?? 'us-east-1',
    s3Bucket: process.env.S3_BUCKET ?? '',
}

export default config;