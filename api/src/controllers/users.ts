import { type Request, type Response } from 'express';
import { type JwtPayload } from 'jsonwebtoken';
import * as reputationService from '../services/reputation.js';

export async function getLeaderboard(req: Request, res: Response): Promise<void> {
    const { id } = req.auth as JwtPayload;
    const leaderboard = await reputationService.getLeaderboard(id);
    res.status(200).json(leaderboard);
}
