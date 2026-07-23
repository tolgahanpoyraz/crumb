import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

class UsersApiException implements Exception {
  UsersApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

String? _optionalString(dynamic value) {
  if (value == null) {
    return null;
  }

  final text = value.toString().trim();

  return text.isEmpty ? null : text;
}

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.userId,
    required this.displayName,
    required this.avatarKey,
    required this.weeklyPoints,
    required this.tier,
    required this.rank,
  });

  final String userId;
  final String displayName;
  final String? avatarKey;
  final int weeklyPoints;
  final int tier;
  final int rank;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: (json['userId'] ?? '').toString(),
      displayName: (json['displayName'] ?? '').toString(),
      avatarKey: _optionalString(json['avatarKey']),
      weeklyPoints:
          json['weeklyPoints'] is num ? (json['weeklyPoints'] as num).toInt() : 0,
      tier: json['tier'] is num ? (json['tier'] as num).toInt() : 0,
      rank: json['rank'] is num ? (json['rank'] as num).toInt() : 0,
    );
  }
}

class LeaderboardMe {
  const LeaderboardMe({
    required this.rank,
    required this.weeklyPoints,
    required this.reputation,
    required this.tier,
  });

  final int? rank;
  final int weeklyPoints;
  final int reputation;
  final int tier;

  factory LeaderboardMe.fromJson(Map<String, dynamic> json) {
    return LeaderboardMe(
      rank: json['rank'] is num ? (json['rank'] as num).toInt() : null,
      weeklyPoints:
          json['weeklyPoints'] is num ? (json['weeklyPoints'] as num).toInt() : 0,
      reputation:
          json['reputation'] is num ? (json['reputation'] as num).toInt() : 0,
      tier: json['tier'] is num ? (json['tier'] as num).toInt() : 0,
    );
  }
}

class Leaderboard {
  const Leaderboard({required this.entries, required this.me});

  final List<LeaderboardEntry> entries;
  final LeaderboardMe me;
}

class UsersApi {
  static Future<Leaderboard> getLeaderboard({required String token}) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/users/leaderboard'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = _decodeResponse(response);

    final entriesJson = data['entries'] as List<dynamic>? ?? [];
    final meValue = data['me'];

    return Leaderboard(
      entries: entriesJson
          .map(
            (entryJson) => LeaderboardEntry.fromJson(
              Map<String, dynamic>.from(entryJson as Map),
            ),
          )
          .toList(),
      me: LeaderboardMe.fromJson(
        meValue is Map ? Map<String, dynamic>.from(meValue) : const {},
      ),
    );
  }

  static Map<String, dynamic> _decodeResponse(http.Response response) {
    Map<String, dynamic> data = {};

    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);

        if (decoded is Map) {
          data = Map<String, dynamic>.from(decoded);
        }
      } on FormatException {
        throw UsersApiException(
          'The server returned an invalid response.',
          statusCode: response.statusCode,
        );
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw UsersApiException(
        data['error']?.toString() ?? 'Request failed.',
        statusCode: response.statusCode,
      );
    }

    return data;
  }
}
