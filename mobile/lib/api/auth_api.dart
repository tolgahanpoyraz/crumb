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
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      _uri('/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'displayName': '${firstName.trim()} ${lastName.trim()}'.trim(),
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