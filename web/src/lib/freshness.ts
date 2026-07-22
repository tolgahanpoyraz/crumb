import type { PostStatus } from '../api/types';

export interface StatusMeta {
  label: string;
  dot: string;
  bg: string;
  text: string;
}

export const STATUS_META: Record<PostStatus, StatusMeta> = {
  fresh: { label: 'Fresh', dot: '#4FB783', bg: '#e7f6ee', text: '#267e4f' },
  likely: { label: 'Likely', dot: '#8bc23f', bg: '#f1f7e4', text: '#5a7a18' },
  fading: { label: 'Fading', dot: '#e8943a', bg: '#fdefe0', text: '#9e5f19' },
  gone: { label: 'Gone', dot: '#c7b8ab', bg: '#f4eee6', text: '#786a5e' },
};

// Mirrors the server's statusFromConfidence (api/src/confidence.ts) for any
// client-side recompute; the feed already ships `status`, so prefer that.
export function statusFromConfidence(p: number): PostStatus {
  return p >= 0.65 ? 'fresh' : p >= 0.5 ? 'likely' : p > 0.15 ? 'fading' : 'gone';
}

export function confidencePct(confidence: number): number {
  return Math.round(confidence * 100);
}

// Freshness meter runs FRESH (left) → GONE (right); a more-confident post sits
// further left. Clamped so the thumb never clips the rounded ends.
export function meterPosition(confidence: number): number {
  const pos = (1 - confidence) * 100;
  return Math.min(96, Math.max(4, pos));
}
