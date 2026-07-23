import 'package:flutter/material.dart';

import '../../theme/reputation.dart';

/// The reputation pill — glyph + tier name. Colors come from the tier's bread
/// ramp, deliberately distinct from the freshness pill. [small] is the compact
/// variant used inline next to names.
class TierBadge extends StatelessWidget {
  const TierBadge({
    super.key,
    required this.tier,
    this.small = false,
  });

  final ReputationTier tier;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final border = tier.borderColor;

    return Container(
      padding: small
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 2)
          : const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: tier.bg,
        borderRadius: BorderRadius.circular(999),
        border: border == null ? null : Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tier.glyph,
            style: TextStyle(fontSize: small ? 10 : 12, height: 1),
          ),
          SizedBox(width: small ? 3 : 5),
          Text(
            tier.name,
            style: TextStyle(
              color: tier.text,
              fontWeight: FontWeight.w600,
              fontSize: small ? 10 : 12,
            ),
          ),
        ],
      ),
    );
  }
}
