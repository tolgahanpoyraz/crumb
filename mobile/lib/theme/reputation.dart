import 'package:flutter/material.dart';

/// Reputation tiers are NOT freshness — a deliberately warm bread ramp
/// (crumb → croissant), kept clear of the green/amber freshness colors so the
/// two badge families never read as the same scale.
enum ReputationTier {
  crumb(
    name: 'Crumb',
    glyph: '🍪',
    bg: Color(0xFFF4ECE3),
    text: Color(0xFF7A5A4D),
    threshold: 0,
  ),
  slice(
    name: 'Slice',
    glyph: '🍞',
    bg: Color(0xFFF6E7D2),
    text: Color(0xFF9A6B2F),
    threshold: 50,
  ),
  loaf(
    name: 'Loaf',
    glyph: '🥖',
    bg: Color(0xFFECD9C2),
    text: Color(0xFF7A4F27),
    threshold: 150,
  ),
  goldenCroissant(
    name: 'Golden Croissant',
    glyph: '🥐',
    bg: Color(0xFFFBF1CF),
    text: Color(0xFFB8860F),
    threshold: 400,
  );

  const ReputationTier({
    required this.name,
    required this.glyph,
    required this.bg,
    required this.text,
    required this.threshold,
  });

  final String name;
  final String glyph;
  final Color bg;
  final Color text;

  /// Reputation floor for this tier; mirrors the server's tier thresholds.
  final int threshold;

  int get level => index;
  bool get isTop => this == ReputationTier.goldenCroissant;

  /// Subtle inset gold frame on the top tier only — rgba(184,134,15,.28).
  Color? get borderColor => isTop ? const Color(0x47B8860F) : null;

  static ReputationTier fromLevel(int? level) {
    switch (level) {
      case 1:
        return ReputationTier.slice;
      case 2:
        return ReputationTier.loaf;
      case 3:
        return ReputationTier.goldenCroissant;
      default:
        return ReputationTier.crumb;
    }
  }

  /// Points needed to reach the next tier, or null at the top tier.
  int? get nextThreshold => isTop ? null : fromLevel(level + 1).threshold;
}

class TierProgress {
  const TierProgress({
    required this.fraction,
    required this.label,
    required this.atTop,
  });

  /// Bar fill in the 0..1 range.
  final double fraction;
  final String? label;
  final bool atTop;
}

/// Fill of the "to next tier" bar, measured from the current tier's floor so
/// the bar starts empty at each new tier rather than jumping.
TierProgress tierProgressFor(int reputation, ReputationTier tier, int? nextTierAt) {
  if (nextTierAt == null) {
    return const TierProgress(fraction: 1, label: null, atTop: true);
  }

  final floor = tier.threshold;
  final span = nextTierAt - floor;
  final fraction =
      span > 0 ? ((reputation - floor) / span).clamp(0.0, 1.0) : 0.0;
  final nextName = ReputationTier.fromLevel(tier.level + 1).name;

  return TierProgress(
    fraction: fraction,
    label: '$reputation / $nextTierAt to $nextName',
    atTop: false,
  );
}
