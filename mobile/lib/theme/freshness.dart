import 'package:flutter/material.dart';

enum FreshnessStatus {
  fresh(
    label: 'Fresh',
    dot: Color(0xFF4FB783),
    badgeBg: Color(0xFFE7F6EE),
    badgeText: Color(0xFF2F9D63),
  ),
  likely(
    label: 'Likely',
    dot: Color(0xFF8BC23F),
    badgeBg: Color(0xFFF1F7E4),
    badgeText: Color(0xFF5E8019),
  ),
  fading(
    label: 'Fading',
    dot: Color(0xFFE8943A),
    badgeBg: Color(0xFFFDEFE0),
    badgeText: Color(0xFFB06A1C),
  ),
  gone(
    label: 'Gone',
    dot: Color(0xFFC7B8AB),
    badgeBg: Color(0xFFF4EEE6),
    badgeText: Color(0xFF8A7A6C),
  );

  const FreshnessStatus({
    required this.label,
    required this.dot,
    required this.badgeBg,
    required this.badgeText,
  });

  final String label;
  final Color dot;
  final Color badgeBg;
  final Color badgeText;

  static FreshnessStatus fromApi(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'likely':
        return FreshnessStatus.likely;
      case 'fading':
        return FreshnessStatus.fading;
      case 'gone':
        return FreshnessStatus.gone;
      case 'fresh':
      default:
        return FreshnessStatus.fresh;
    }
  }
}

class FreshnessMeter extends StatelessWidget {
  const FreshnessMeter({
    super.key,
    required this.confidence,
    required this.status,
  });

  /// Confidence in the 0..1 range; positions the thumb.
  final double confidence;
  final FreshnessStatus status;

  static const _gradient = LinearGradient(
    colors: [
      Color(0xFF4FB783),
      Color(0xFF8BC23F),
      Color(0xFFE8943A),
      Color(0xFFC7B8AB),
    ],
    stops: [0.0, 0.38, 0.72, 1.0],
  );

  @override
  Widget build(BuildContext context) {
    final value = confidence.clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        const barHeight = 8.0;
        const thumbSize = 16.0;
        final thumbLeft = (constraints.maxWidth - thumbSize) * value;

        return SizedBox(
          height: thumbSize,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: barHeight,
                decoration: const BoxDecoration(
                  gradient: _gradient,
                  borderRadius: BorderRadius.all(Radius.circular(999)),
                ),
              ),
              Positioned(
                left: thumbLeft,
                child: Container(
                  width: thumbSize,
                  height: thumbSize,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: status.dot, width: 3),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
