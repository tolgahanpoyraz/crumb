import type { Tier } from '../api/types';

export interface TierMeta {
  name: string;
  glyph: string;
  bg: string;
  text: string;
}

// Reputation tiers are NOT freshness — deliberately a warm bread ramp (crumb →
// croissant), kept clear of the green/amber freshness colors so the two badge
// families never read as the same scale.
export const TIER_META: Record<Tier, TierMeta> = {
  0: { name: 'Crumb', glyph: '🍪', bg: '#f4ece3', text: '#7a5a4d' },
  1: { name: 'Slice', glyph: '🍞', bg: '#f6e7d2', text: '#9a6b2f' },
  2: { name: 'Loaf', glyph: '🥖', bg: '#ecd9c2', text: '#7a4f27' },
  3: { name: 'Golden Croissant', glyph: '🥐', bg: '#fbf1cf', text: '#b8860f' },
};

// Reputation floor for each tier; mirrors the server's tier thresholds.
export const TIER_THRESHOLDS = [0, 50, 150, 400];

export interface TierProgress {
  pct: number;
  label: string | null;
  atTop: boolean;
}

// Fill of the "to next tier" bar, measured from the current tier's floor so the
// bar starts empty at each new tier rather than jumping.
export function tierProgress(reputation: number, tier: Tier, nextTierAt: number | null): TierProgress {
  if (nextTierAt === null) {
    return { pct: 100, label: null, atTop: true };
  }
  const floor = TIER_THRESHOLDS[tier] ?? 0;
  const span = nextTierAt - floor;
  const pct = span > 0 ? Math.min(100, Math.max(0, ((reputation - floor) / span) * 100)) : 0;
  const nextName = TIER_META[(tier + 1) as Tier].name;
  return { pct, label: `${reputation} / ${nextTierAt} to ${nextName}`, atTop: false };
}
