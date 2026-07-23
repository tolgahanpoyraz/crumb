import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../api/auth_api.dart';

class AuthSession extends ChangeNotifier {
  AuthSession(this._authApi);

  final AuthApi _authApi;

  static const String _tokenKey = 'auth_token';

  String? _token;
  Map<String, dynamic>? _user;
  bool _isLoading = false;
  bool _sessionLoadFailed = false;
  int _avatarVersion = 0;

  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _token != null && _user != null;

  /// Reputation fields off the /auth/me user (an untyped map). Default to a
  /// Crumb-tier profile when absent, e.g. right after a login response that
  /// predates the reputation refresh.
  int get reputation {
    final value = _user?['reputation'];
    return value is num ? value.toInt() : 0;
  }

  int get tier {
    final value = _user?['tier'];
    return value is num ? value.toInt().clamp(0, 3) : 0;
  }

  int? get nextTierAt {
    final value = _user?['nextTierAt'];
    return value is num ? value.toInt() : null;
  }

  /// Bumped each time [updateAvatar] succeeds, so avatar URLs built from the
  /// (unchanged) S3 key can bust the image cache.
  int get avatarVersion => _avatarVersion;

  /// True when a saved token exists but the profile could not be fetched due to
  /// a transient (network/5xx) error — the token is kept and the load can retry.
  bool get sessionLoadFailed => _sessionLoadFailed;

  Future<void> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);

    if (_token != null) {
      await _fetchMe();
    }

    notifyListeners();
  }

  Future<void> retryLoad() async {
    if (_token == null) {
      return;
    }

    _setLoading(true);
    try {
      await _fetchMe();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _fetchMe() async {
    try {
      final data = await _authApi.getMe(_token!);
      _user = data['user'] as Map<String, dynamic>?;
      _sessionLoadFailed = false;
    } on AuthApiException catch (error) {
      if (error.statusCode == 401) {
        await logout();
      } else {
        _sessionLoadFailed = true;
      }
    } catch (_) {
      _sessionLoadFailed = true;
    }
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
      _sessionLoadFailed = false;

      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<String> register({
    required String displayName,
    required String email,
    required String password,
  }) async {
    _setLoading(true);

    try {
      final data = await _authApi.register(
        displayName: displayName,
        email: email,
        password: password,
      );

      return data['message']?.toString() ??
          'Account created. Check your email to verify your account.';
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

  Future<String> forgotPassword({
    required String email,
  }) async {
    _setLoading(true);

    try {
      final data = await _authApi.forgotPassword(email: email);
      return data['message']?.toString() ??
          'If that account exists, a reset link is on its way.';
    } finally {
      _setLoading(false);
    }
  }

  Future<String> resetPassword({
    required String token,
    required String password,
  }) async {
    _setLoading(true);

    try {
      final data = await _authApi.resetPassword(
        token: token,
        password: password,
      );
      return data['message']?.toString() ??
          'Password reset. You can now log in.';
    } finally {
      _setLoading(false);
    }
  }

  /// Changes the password and swaps in the fresh token the server returns
  /// (the old token is invalidated server-side).
  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final token = _token;
    if (token == null) {
      throw AuthApiException('You are not signed in.');
    }

    _setLoading(true);
    try {
      final freshToken = await _authApi.changePassword(
        token: token,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, freshToken);
      _token = freshToken;

      notifyListeners();
      return 'Password changed.';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateAvatar({
    required List<int> bytes,
    required String contentType,
  }) async {
    final token = _token;
    if (token == null) {
      throw AuthApiException('You are not signed in.');
    }

    _setLoading(true);
    try {
      final upload = await _authApi.getAvatarUploadUrl(token);

      final putResponse = await http.put(
        Uri.parse(upload['url']!),
        headers: {'Content-Type': contentType},
        body: bytes,
      );

      if (putResponse.statusCode < 200 || putResponse.statusCode >= 300) {
        throw AuthApiException(
          'Avatar upload failed.',
          statusCode: putResponse.statusCode,
        );
      }

      final data = await _authApi.setAvatar(token);
      _user = data['user'] as Map<String, dynamic>? ?? _user;
      _avatarVersion++;

      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);

    _token = null;
    _user = null;
    _sessionLoadFailed = false;

    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
