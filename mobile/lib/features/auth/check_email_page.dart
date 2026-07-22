import 'package:flutter/material.dart';

import '../../api/auth_api.dart';
import 'auth_session.dart';
import 'auth_ui.dart';
import 'confirmation_body.dart';
import 'set_new_password_page.dart';

class CheckEmailPage extends StatelessWidget {
  const CheckEmailPage({
    super.key,
    required this.authSession,
    required this.email,
  });

  final AuthSession authSession;
  final String email;

  Future<void> _resend(BuildContext context) async {
    try {
      final message = await authSession.forgotPassword(email: email);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } on AuthApiException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      sticker: 'starstruck.png',
      tagline: "Eugene's on it.",
      children: [
        ConfirmationBody(
          title: 'Check your email',
          leadStrong: 'We sent a reset link to ',
          email: email,
          trail: '. Open it in your browser to set a new password.',
        ),
        const SizedBox(height: 26),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
          child: const Text('Back to log in'),
        ),
        const SizedBox(height: 14),
        OutlinedButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => SetNewPasswordPage(authSession: authSession),
            ),
          ),
          child: const Text('Already have a code or link?'),
        ),
        const SizedBox(height: 18),
        AuthFooterLink(
          prompt: "Didn't get it?",
          action: 'Resend link',
          onTap: () => _resend(context),
        ),
      ],
    );
  }
}
