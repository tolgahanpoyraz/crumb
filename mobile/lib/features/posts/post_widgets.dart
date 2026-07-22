import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../theme/freshness.dart';

/// Freshness status pill (label + dot) reused on rows and the detail sheet.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.status,
    this.fontSize = 11,
    this.padding = const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
  });

  final FreshnessStatus status;
  final double fontSize;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: status.badgeBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: status.dot,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: TextStyle(
              color: status.badgeText,
              fontWeight: FontWeight.w700,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }
}

/// Cover-fit food photo with a warm placeholder fallback.
class PostThumbnail extends StatelessWidget {
  const PostThumbnail({
    super.key,
    required this.imageUrl,
    required this.width,
    required this.height,
    this.radius = 13,
    this.iconSize = 26,
  });

  final String? imageUrl;
  final double width;
  final double height;
  final double radius;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: width,
        height: height,
        child: url == null
            ? _placeholder()
            : Image.network(
                url,
                width: width,
                height: height,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) {
                    return child;
                  }
                  return _placeholder(loading: true);
                },
                errorBuilder: (_, __, ___) => _placeholder(),
              ),
      ),
    );
  }

  Widget _placeholder({bool loading = false}) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.coralLight, AppColors.border],
        ),
      ),
      child: Center(
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                Icons.lunch_dining_rounded,
                size: iconSize,
                color: Colors.white,
              ),
      ),
    );
  }
}

/// Type / dietary tag chip on the detail sheet.
class PostTag extends StatelessWidget {
  const PostTag({
    super.key,
    required this.label,
    this.icon,
    this.dietary = false,
  });

  final String label;
  final IconData? icon;
  final bool dietary;

  @override
  Widget build(BuildContext context) {
    final bg = dietary
        ? FreshnessStatus.fresh.badgeBg
        : const Color(0xFFF4ECE3);
    final fg = dietary ? FreshnessStatus.fresh.badgeText : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
