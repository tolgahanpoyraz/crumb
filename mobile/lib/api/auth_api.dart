import 'dart:convert';

import 'package:http/http.dart' as http;

import './api_config.dart';

class AuthApiException implements Exception {
  AuthApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class AuthApi {
  Uri _uri(String path) {
    return Uri.parse('${ApiConfig.baseUrl}$path');
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      _uri('/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
      }),
    );

    return _handleJsonResponse(response);
  }

  Future<Map<String, dynamic>> register({
    required String displayName,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      _uri('/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'displayName': displayName.trim(),
        'email': email.trim(),
        'password': password,
      }),
    );

    return _handleJsonResponse(response);
  }

  Future<Map<String, dynamic>> getMe(String token) async {
    final response = await http.get(
      _uri('/auth/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    return _handleJsonResponse(response);
  }

  Future<Map<String, dynamic>> resendVerification({
    required String email,
  }) async {
    final response = await http.post(
      _uri('/auth/resend-verification'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim(),
      }),
    );

    return _handleJsonResponse(response);
  }

  Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    final response = await http.post(
      _uri('/auth/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim(),
      }),
    );

    return _handleJsonResponse(response);
  }

  Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String password,
  }) async {
    final response = await http.post(
      _uri('/auth/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'token': token.trim(),
        'password': password,
      }),
    );

    return _handleJsonResponse(response);
  }

  /// Returns the fresh JWT that replaces the caller's now-invalidated token.
  Future<String> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await http.post(
      _uri('/auth/change-password'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );

    final data = _handleJsonResponse(response);
    final freshToken = data['token']?.toString();

    if (freshToken == null || freshToken.isEmpty) {
      throw AuthApiException(
        'The server did not return a new session token.',
        statusCode: response.statusCode,
      );
    }

    return freshToken;
  }

  Future<Map<String, String>> getAvatarUploadUrl(String token) async {
    final response = await http.get(
      _uri('/auth/me/avatar-upload-url'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = _handleJsonResponse(response);
    final url = data['url']?.toString();
    final key = data['key']?.toString();

    if (url == null || url.isEmpty || key == null || key.isEmpty) {
      throw AuthApiException(
        'The server returned an invalid upload URL.',
        statusCode: response.statusCode,
      );
    }

    return {'url': url, 'key': key};
  }

  Future<Map<String, dynamic>> setAvatar(String token) async {
    final response = await http.post(
      _uri('/auth/me/avatar'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    return _handleJsonResponse(response);
  }

  Map<String, dynamic> _handleJsonResponse(http.Response response) {
    final decoded = response.body.isNotEmpty
        ? jsonDecode(response.body) as Map<String, dynamic>
        : <String, dynamic>{};

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    final message = decoded['error']?.toString() ?? 'Request failed';

    throw AuthApiException(
      message,
      statusCode: response.statusCode,
    );
  }
}