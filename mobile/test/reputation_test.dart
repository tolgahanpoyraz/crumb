import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/theme/reputation.dart';

void main() {
  group('ReputationTier', () {
    test('levels map to the bread ramp', () {
      expect(ReputationTier.fromLevel(0), ReputationTier.crumb);
      expect(ReputationTier.fromLevel(1), ReputationTier.slice);
      expect(ReputationTier.fromLevel(2), ReputationTier.loaf);
      expect(ReputationTier.fromLevel(3), ReputationTier.goldenCroissant);
    });

    test('unknown or missing level falls back to Crumb', () {
      expect(ReputationTier.fromLevel(null), ReputationTier.crumb);
      expect(ReputationTier.fromLevel(9), ReputationTier.crumb);
    });

    test('thresholds mirror the server', () {
      expect(ReputationTier.crumb.threshold, 0);
      expect(ReputationTier.slice.threshold, 50);
      expect(ReputationTier.loaf.threshold, 150);
      expect(ReputationTier.goldenCroissant.threshold, 400);
    });

    test('only the top tier is topped out and gets a border', () {
      expect(ReputationTier.goldenCroissant.isTop, isTrue);
      expect(ReputationTier.goldenCroissant.nextThreshold, isNull);
      expect(ReputationTier.goldenCroissant.borderColor, isNotNull);
      expect(ReputationTier.crumb.borderColor, isNull);
      expect(ReputationTier.crumb.nextThreshold, 50);
    });
  });

  group('tierProgressFor', () {
    test('measures fill from the current tier floor', () {
      final progress = tierProgressFor(84, ReputationTier.slice, 150);
      // (84 - 50) / (150 - 50) = 0.34
      expect(progress.fraction, closeTo(0.34, 0.0001));
      expect(progress.label, '84 / 150 to Loaf');
      expect(progress.atTop, isFalse);
    });

    test('clamps into 0..1', () {
      expect(tierProgressFor(0, ReputationTier.slice, 150).fraction, 0);
      expect(tierProgressFor(999, ReputationTier.slice, 150).fraction, 1);
    });

    test('null next threshold is topped out', () {
      final progress =
          tierProgressFor(500, ReputationTier.goldenCroissant, null);
      expect(progress.atTop, isTrue);
      expect(progress.label, isNull);
      expect(progress.fraction, 1);
    });
  });
}
