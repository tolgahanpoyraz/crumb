import type { Tier } from '../api/types';
import { TIER_META } from '../lib/reputation';

interface TierBadgeProps {
  tier: Tier;
  variant?: 'pill' | 'sm';
}

// The reputation pill — glyph + tier name. Colors come from TIER_META (the bread
// ramp), deliberately distinct from the freshness pill.
export function TierBadge({ tier, variant = 'pill' }: TierBadgeProps) {
  const meta = TIER_META[tier];
  return (
    <span
      className={`tier-badge ${variant === 'sm' ? 'sm' : ''} ${tier === 3 ? 'gold' : ''}`}
      style={{ background: meta.bg, color: meta.text }}
    >
      <span className="glyph" aria-hidden="true">
        {meta.glyph}
      </span>
      {meta.name}
    </span>
  );
}
