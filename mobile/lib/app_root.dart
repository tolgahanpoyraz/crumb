import 'package:flutter/material.dart';

import 'api/auth_api.dart';
import 'app_shell.dart';
import 'features/auth/auth_session.dart';
import 'theme/app_theme.dart';

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'crumb',
                style: TextStyle(
                  color: AppColors.coral,
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.8,
                ),
              ),
              SizedBox(height: 20),
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            ],
          ),
        ),
      );
    }

    return AppShell(authSession: _authSession);
  }
}
