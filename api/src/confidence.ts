import { type VoteType, type PostStatus } from './models/Post.js';

export const E_INITIAL = 2.0;
const E_PRIOR = -2.5;            // log-odds decays toward this
const LAMBDA = Math.LN2 / 20;    // 20-minute half-life
export const E_FLOOR = Math.log(0.15 / 0.85);   // logit(0.15) the gone threshold

const VOTE_WEIGHT: Record<VoteType, number> = {
    present: 1.5,
    gone: -3.0,
};

export const sigmoid = (E: number): number => 1 / (1 + Math.exp(-E));

export function applyVote(E: number, type: VoteType): number {
    return E + VOTE_WEIGHT[type];
}

export function decayE(E: number, minutesElapsed: number): number {
    return E_PRIOR + (E - E_PRIOR) * Math.exp(-LAMBDA * minutesElapsed);
}

export function expiryFromE(E: number, now: Date): Date {
    if (E <= E_FLOOR) {
        return now;
    }
    const minutes = (1 / LAMBDA) * Math.log((E - E_PRIOR) / (E_FLOOR - E_PRIOR));
    return new Date(now.getTime() + minutes * 60000);
}

export function statusFromConfidence(p: number): PostStatus {
    return p >= 0.65 ? 'fresh' : p >= 0.5 ? 'likely' : p > 0.15 ? 'fading' : 'gone';
}