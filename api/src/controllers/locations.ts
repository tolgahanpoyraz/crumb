import { type Request, type Response } from 'express';
import { listLocations } from '../locations.js';

export async function getLocations(_req: Request, res: Response): Promise<void> {
    res.status(200).json({ locations: listLocations() });
}