import 'package:flutter/material.dart';

import '../../api/auth_api.dart';
import 'auth_session.dart';
import 'auth_ui.dart';
import 'check_email_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key, required this.authSession});

  final AuthSession authSession;

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);

    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Enter your school email first.');
      return;
    }

    try {
      await widget.authSession.forgotPassword(email: email);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => CheckEmailPage(
            authSession: widget.authSession,
            email: email,
          ),
        ),
      );
    } on AuthApiException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = 'Something went wrong. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = widget.authSession.isLoading;

    return AuthScaffold(
      sticker: 'silly.png',
      tagline: 'Happens to everyone.',
      showBack: true,
      children: [
        Text(
          'Reset your password',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 6),
        Text(
          "Enter your school email and we'll send you a reset link.",
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 22),
        const AuthFieldLabel('School email'),
        const SizedBox(height: 7),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.email],
          onSubmitted: (_) => _submit(),
          decoration: const InputDecoration(
            hintText: 'you@ucf.edu',
            prefixIcon: Icon(Icons.mail_outline_rounded),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 16),
          AuthMessageBanner(message: _error!, isError: true),
        ],
        const SizedBox(height: 22),
        FilledButton(
          onPressed: isLoading ? null : _submit,
          child: isLoading
              ? const AuthButtonSpinner()
              : const Text('Send reset link'),
        ),
        const SizedBox(height: 22),
        AuthFooterLink(
          prompt: 'Remembered it?',
          action: 'Log in',
          onTap: () => Navigator.of(context).maybePop(),
        ),
      ],
    );
  }
}
