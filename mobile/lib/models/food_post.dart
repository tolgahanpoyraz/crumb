class CampusLocation {
  const CampusLocation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  final String id;
  final String name;
  final double? latitude;
  final double? longitude;

  factory CampusLocation.fromJson(Map<String, dynamic> json) {
    return CampusLocation(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      latitude: json['latitude'] is num
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] is num
          ? (json['longitude'] as num).toDouble()
          : null,
    );
  }

  /// Supports older posts where location may still be a plain string.
  factory CampusLocation.fromValue(dynamic value) {
    if (value is Map<String, dynamic>) {
      return CampusLocation.fromJson(value);
    }

    if (value is Map) {
      return CampusLocation.fromJson(
        Map<String, dynamic>.from(value),
      );
    }

    final locationText = value?.toString() ?? '';

    return CampusLocation(
      id: locationText,
      name: locationText,
      latitude: null,
      longitude: null,
    );
  }
}

class FoodPost {
  const FoodPost({
    required this.id,
    required this.foodName,
    required this.type,
    required this.dietaryTags,
    required this.location,
    required this.locationDetail,
    required this.imageKey,
    required this.authorId,
    required this.status,
    required this.confidence,
    required this.presentVotes,
    required this.goneVotes,
    required this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String foodName;

  /// One of:
  /// pizza, meal, snacks, baked-goods, drinks, other
  final String type;

  /// Possible values:
  /// vegetarian, vegan, halal, kosher, gluten-free
  final List<String> dietaryTags;

  final CampusLocation location;
  final String? locationDetail;
  final String? imageKey;
  final String authorId;
  final String status;
  final double? confidence;
  final int presentVotes;
  final int goneVotes;
  final DateTime? expiresAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory FoodPost.fromJson(Map<String, dynamic> json) {
    final talliesValue = json['tallies'];

    final tallies = talliesValue is Map
        ? Map<String, dynamic>.from(talliesValue)
        : <String, dynamic>{};

    final dietaryTagsValue =
        json['dietaryTags'] ?? json['badges'];

    return FoodPost(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      foodName: (json['foodName'] ?? '').toString(),
      type: (json['type'] ?? 'other').toString(),
      dietaryTags: dietaryTagsValue is List
          ? dietaryTagsValue
              .map((tag) => tag.toString())
              .toList()
          : const [],
      location: CampusLocation.fromValue(json['location']),
      locationDetail: _optionalString(json['locationDetail']),
      imageKey: _optionalString(json['imageKey']),
      authorId: _parseAuthorId(json['author']),
      status: (json['status'] ?? 'fresh').toString(),
      confidence: json['confidence'] is num
          ? (json['confidence'] as num).toDouble()
          : null,
      presentVotes: tallies['present'] is num
          ? (tallies['present'] as num).toInt()
          : 0,
      goneVotes: tallies['gone'] is num
          ? (tallies['gone'] as num).toInt()
          : 0,
      expiresAt: _parseDate(json['expiresAt']),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  static String? _optionalString(dynamic value) {
    if (value == null) {
      return null;
    }

    final text = value.toString().trim();

    return text.isEmpty ? null : text;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }

  static String _parseAuthorId(dynamic value) {
    if (value is Map) {
      return (value['_id'] ?? value['id'] ?? '').toString();
    }

    return value?.toString() ?? '';
  }
}