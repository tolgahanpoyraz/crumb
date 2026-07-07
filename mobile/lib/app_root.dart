import 'package:flutter/material.dart';

import 'api/auth_api.dart';
import 'app_shell.dart';
import 'features/auth/auth_session.dart';

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  late final AuthSession _authSession;
  bool _isCheckingSavedLogin = true;

  @override
  void initState() {
    super.initState();

    _authSession = AuthSession(AuthApi());
    _loadSavedLogin();
  }

  Future<void> _loadSavedLogin() async {
    await _authSession.loadFromStorage();

    if (!mounted) return;

    setState(() {
      _isCheckingSavedLogin = false;
    });
  }

  @override
  void dispose() {
    _authSession.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingSavedLogin) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return AppShell(authSession: _authSession);
  }
}