import { createServer } from 'http';
import { afterAll, beforeAll } from 'vitest';
import app from '../src/app.js';

export const server = createServer(app);

beforeAll(async () => {
    await new Promise<void>((resolve) => server.listen(0, '127.0.0.1', resolve));
});

afterAll(async () => {
    await new Promise<void>((resolve, reject) => server.close((err) => (err ? reject(err) : resolve())));
});
