import 'package:flutter/material.dart';

import '../../api/auth_api.dart';
import 'auth_session.dart';
import 'auth_ui.dart';
import 'confirmation_body.dart';

class VerifyEmailPage extends StatelessWidget {
  const VerifyEmailPage({
    super.key,
    required this.authSession,
    required this.email,
  });

  final AuthSession authSession;
  final String email;

  Future<void> _resend(BuildContext context) async {
    try {
      final message = await authSession.resendVerification(email: email);
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
      tagline: "One quick step and you're in.",
      children: [
        ConfirmationBody(
          title: 'Verify your email',
          leadStrong: 'We sent a verification link to ',
          email: email,
          trail:
              ". Tap it to activate — you'll need to verify before you can log in.",
        ),
        const SizedBox(height: 26),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
          child: const Text('Back to log in'),
        ),
        const SizedBox(height: 20),
        AuthFooterLink(
          prompt: "Didn't get it?",
          action: 'Resend verification link',
          onTap: () => _resend(context),
        ),
      ],
    );
  }
}
