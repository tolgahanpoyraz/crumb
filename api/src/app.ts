import express from 'express';
import cors from 'cors';
import { pinoHttp } from 'pino-http';
import config from './config/env.js';
import logger from './config/logger.js';
import routes from './routes/index.js';
import { errorHandler } from './middleware/errorHandler.js';

const app = express();

app.use(pinoHttp({ logger }));
app.use(cors(config.corsOrigins.length ? { origin: config.corsOrigins } : {}));
app.use(express.json());

app.use('/api', routes);
app.use(errorHandler);

export default app;