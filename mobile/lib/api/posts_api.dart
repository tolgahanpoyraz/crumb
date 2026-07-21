import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/food_post.dart';
import 'api_config.dart';

class PostsApiException implements Exception {
  PostsApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class PostsApi {
  static Future<List<FoodPost>> getFeed() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/posts'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    final data = _decodeResponse(response);
    final postsJson = data['posts'] as List<dynamic>? ?? [];

    return postsJson
        .map(
          (postJson) => FoodPost.fromJson(
            Map<String, dynamic>.from(postJson as Map),
          ),
        )
        .toList();
  }

  static Future<List<CampusLocation>> getLocations() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/locations'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    final data = _decodeResponse(response);
    final locationsJson = data['locations'] as List<dynamic>? ?? [];

    return locationsJson
        .map(
          (locationJson) => CampusLocation.fromJson(
            Map<String, dynamic>.from(locationJson as Map),
          ),
        )
        .toList();
  }

  static Future<FoodPost> createPost({
    required String token,
    required String foodName,
    required String type,
    required String locationId,
    required List<String> dietaryTags,
    String? locationDetail,
    String? imageKey,
  }) async {
    final body = <String, dynamic>{
      'foodName': foodName.trim(),
      'type': type,
      'location': locationId,
      'dietaryTags': dietaryTags,
    };

    final trimmedLocationDetail = locationDetail?.trim();

    if (trimmedLocationDetail != null &&
        trimmedLocationDetail.isNotEmpty) {
      body['locationDetail'] = trimmedLocationDetail;
    }

    if (imageKey != null && imageKey.isNotEmpty) {
      body['imageKey'] = imageKey;
    }

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/posts'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    final data = _decodeResponse(response);
    final postValue = data['post'];

    if (postValue is! Map) {
      throw PostsApiException(
        'The server returned an invalid post response.',
        statusCode: response.statusCode,
      );
    }

    return FoodPost.fromJson(
      Map<String, dynamic>.from(postValue),
    );
  }

  static Future<void> votePost({
    required String token,
    required String postId,
    required String type,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/posts/$postId/vote'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'type': type,
      }),
    );

    _decodeResponse(response);
  }

  static Future<Map<String, String>> getUploadUrl({
    required String token,
  }) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/posts/upload-url'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = _decodeResponse(response);

    final url = data['url']?.toString();
    final key = data['key']?.toString();

    if (url == null || url.isEmpty || key == null || key.isEmpty) {
      throw PostsApiException(
        'The server returned an invalid upload URL.',
        statusCode: response.statusCode,
      );
    }

    return {
      'url': url,
      'key': key,
    };
  }

  static Future<String> uploadImageBytes({
    required String token,
    required List<int> bytes,
    required String contentType,
  }) async {
    final uploadData = await getUploadUrl(token: token);

    final uploadUrl = uploadData['url']!;
    final imageKey = uploadData['key']!;

    final uploadResponse = await http.put(
      Uri.parse(uploadUrl),
      headers: {
        'Content-Type': contentType,
      },
      body: bytes,
    );

    if (uploadResponse.statusCode < 200 ||
        uploadResponse.statusCode >= 300) {
      throw PostsApiException(
        'Image upload failed.',
        statusCode: uploadResponse.statusCode,
      );
    }

    return imageKey;
  }

  static Map<String, dynamic> _decodeResponse(
    http.Response response,
  ) {
    Map<String, dynamic> data = {};

    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);

        if (decoded is Map) {
          data = Map<String, dynamic>.from(decoded);
        }
      } on FormatException {
        throw PostsApiException(
          'The server returned an invalid response.',
          statusCode: response.statusCode,
        );
      }
    }

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw PostsApiException(
        data['error']?.toString() ?? 'Request failed.',
        statusCode: response.statusCode,
      );
    }

    return data;
  }
}