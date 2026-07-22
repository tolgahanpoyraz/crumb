import '../../api/api_config.dart';
import '../../models/food_post.dart';

/// Shared formatting helpers for the posts surfaces (feed rows, detail sheet).
abstract final class PostFormat {
  static const Map<String, String> foodTypeLabels = {
    'pizza': 'Pizza',
    'meal': 'Meal',
    'snacks': 'Snacks',
    'baked-goods': 'Baked goods',
    'drinks': 'Drinks',
    'other': 'Other',
  };

  static const Map<String, String> dietaryTagLabels = {
    'vegetarian': 'Vegetarian',
    'vegan': 'Vegan',
    'halal': 'Halal',
    'kosher': 'Kosher',
    'gluten-free': 'Gluten-free',
  };

  static String foodType(String type) =>
      foodTypeLabels[type] ?? _capitalizeWords(type);

  static String dietaryTag(String tag) =>
      dietaryTagLabels[tag] ?? _capitalizeWords(tag);

  static String locationName(FoodPost post) {
    final name = post.location.name.trim();
    if (name.isNotEmpty) {
      return name;
    }

    final id = post.location.id.trim();
    if (id.isNotEmpty) {
      return _capitalizeWords(id);
    }

    return 'Unknown location';
  }

  static String? imageUrl(String? imageKey) {
    if (imageKey == null || imageKey.trim().isEmpty) {
      return null;
    }

    final trimmedKey = imageKey.trim();

    if (trimmedKey.startsWith('http://') ||
        trimmedKey.startsWith('https://')) {
      return trimmedKey;
    }

    final baseUrl = ApiConfig.imageBaseUrl.replaceAll(RegExp(r'/$'), '');
    final normalizedKey = trimmedKey.replaceFirst(RegExp(r'^/'), '');
    return '$baseUrl/$normalizedKey';
  }

  static String relativeTime(DateTime? date) {
    if (date == null) {
      return 'Recently';
    }

    final difference = DateTime.now().difference(date.toLocal());
    if (difference.isNegative || difference.inMinutes < 1) {
      return 'Just now';
    }
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }

    final local = date.toLocal();
    return '${local.month}/${local.day}';
  }

  /// e.g. "1h 46m" until expiry, or null when already expired/unknown.
  static String? timeLeft(DateTime? expiresAt) {
    if (expiresAt == null) {
      return null;
    }

    final remaining = expiresAt.toLocal().difference(DateTime.now());
    if (remaining.isNegative || remaining.inMinutes < 1) {
      return null;
    }

    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  static String _capitalizeWords(String value) {
    return value
        .replaceAll('-', ' ')
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map(
          (word) =>
              '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }
}
