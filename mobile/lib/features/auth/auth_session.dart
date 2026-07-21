import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../api/auth_api.dart';

class AuthSession extends ChangeNotifier {
  AuthSession(this._authApi);

  final AuthApi _authApi;

  static const String _tokenKey = 'auth_token';

  String? _token;
  Map<String, dynamic>? _user;
  bool _isLoading = false;

  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _token != null;

  Future<void> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);

    if (_token != null) {
      try {
        final data = await _authApi.getMe(_token!);
        _user = data['user'] as Map<String, dynamic>?;
      } catch (_) {
        await logout();
      }
    }

    notifyListeners();
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);

    try {
      final data = await _authApi.login(
        email: email,
        password: password,
      );

      final token = data['token'] as String;
      final user = data['user'] as Map<String, dynamic>;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);

      _token = token;
      _user = user;

      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<String> register({
  required String firstName,
  required String lastName,
  required String email,
  required String password,
}) async {
  _setLoading(true);

  try {
    final data = await _authApi.register(
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password,
    );

    try {
      await _authApi.resendVerification(email: email);
    } catch (_) {
      return data['message']?.toString() ??
          'Account created, but we could not send the verification email.';
    }

    return 'Account created. Check your email to verify your account.';
  } finally {
    _setLoading(false);
  }
}

  Future<String> resendVerification({
    required String email,
  }) async {
    _setLoading(true);

    try {
      final data = await _authApi.resendVerification(email: email);
      return data['message']?.toString() ?? 'Verification email sent.';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);

    _token = null;
    _user = null;

    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}