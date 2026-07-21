import { describe, it, expect } from 'vitest';
import request from 'supertest';

import { server } from './server.js';

describe('GET /api/locations', () => {
    it('returns the campus location list', async () => {
        const res = await request(server).get('/api/locations');
        expect(res.status).toBe(200);
        expect(Array.isArray(res.body.locations)).toBe(true);
        expect(res.body.locations.length).toBeGreaterThan(0);
        expect(res.body.locations[0]).toMatchObject({
            id: expect.any(String),
            name: expect.any(String),
            latitude: expect.any(Number),
            longitude: expect.any(Number),
        });
    });
});