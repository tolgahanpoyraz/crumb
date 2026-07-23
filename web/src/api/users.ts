import { request } from './client';
import type { LeaderboardResponse } from './types';

export function getLeaderboard(signal?: AbortSignal) {
  return request<LeaderboardResponse>('/users/leaderboard', { auth: true, signal });
}
