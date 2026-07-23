export const TIER_THRESHOLDS = [0, 50, 150, 400];        // tier = highest index whose threshold <= reputation
export const TIER_PRIOR_BONUS = [0, 0.3, 0.6, 1.0];      // added to E_INITIAL for new posts by that tier
export const TIER_VOTE_MULTIPLIER = [1, 1.1, 1.25, 1.5]; // scales VOTE_WEIGHTS for that voter's tier

export const CONFIRM_AWARD = 10;    // author award per confirming present-vote
export const CONFIRM_CAP = 3;       // only the first 3 present votes on a post award the author
export const VOTE_AWARD = 2;        // voter award for any vote
export const PHANTOM_PENALTY = -15; // author penalty when a post looks fake

export function tierFor(reputation: number): number {
    let tier = 0;
    for (let i = 0; i < TIER_THRESHOLDS.length; i++) {
        if (reputation >= TIER_THRESHOLDS[i]) {
            tier = i;
        }
    }
    return tier;
}

export function nextTierAt(reputation: number): number | null {
    const tier = tierFor(reputation);
    if (tier >= TIER_THRESHOLDS.length - 1) {
        return null;
    }
    return TIER_THRESHOLDS[tier + 1];
}
