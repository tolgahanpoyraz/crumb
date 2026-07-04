import pino from 'pino';
import config from './env.js';

const logger = pino({
    level: config.nodeEnv === 'test' ? 'silent' : process.env.LOG_LEVEL ?? 'info',
    transport: config.nodeEnv === 'development'
        ? {
            target: 'pino-pretty',
            options: {
                colorize: true,
                translateTime: 'SYS:HH:MM:ss.l',
                ignore: 'pid,hostname',
            },
        }
        : undefined,
});

export default logger;