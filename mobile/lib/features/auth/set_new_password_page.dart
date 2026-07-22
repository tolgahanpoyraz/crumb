import 'package:flutter/material.dart';

import '../../api/auth_api.dart';
import 'auth_session.dart';
import 'auth_ui.dart';

class SetNewPasswordPage extends StatefulWidget {
  const SetNewPasswordPage({super.key, required this.authSession});

  final AuthSession authSession;

  @override
  State<SetNewPasswordPage> createState() => _SetNewPasswordPageState();
}

class _SetNewPasswordPageState extends State<SetNewPasswordPage> {
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  String? _error;

  @override
  void dispose() {
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  /// Accepts either a raw token or a full reset URL and pulls the token out.
  String _extractToken(String raw) {
    final value = raw.trim();
    final uri = Uri.tryParse(value);
    final fromQuery = uri?.queryParameters['token'];
    return (fromQuery != null && fromQuery.isNotEmpty) ? fromQuery : value;
  }

  Future<void> _submit() async {
    setState(() => _error = null);

    final token = _extractToken(_tokenController.text);
    final password = _passwordController.text;

    if (token.isEmpty) {
      setState(() => _error = 'Paste the reset link or code from your email.');
      return;
    }
    if (password != _confirmController.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }

    try {
      await widget.authSession.resetPassword(token: token, password: password);
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset. Log in with your new password.'),
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
      sticker: 'cheering.png',
      tagline: 'Almost there — pick a new one.',
      showBack: true,
      variant: AuthHeaderVariant.green,
      children: [
        Text('New password', style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 5),
        Text(
          "Choose one you don't use anywhere else.",
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        const AuthFieldLabel('Reset link or code'),
        const SizedBox(height: 7),
        TextField(
          controller: _tokenController,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            hintText: 'Paste the link from your email',
            prefixIcon: Icon(Icons.link_rounded),
          ),
        ),
        const SizedBox(height: 16),
        const AuthFieldLabel('New password'),
        const SizedBox(height: 7),
        PasswordField(
          controller: _passwordController,
          hintText: 'Create a new password',
          autofillHints: const [AutofillHints.newPassword],
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 10),
        PasswordStrengthMeter(password: _passwordController.text),
        const SizedBox(height: 16),
        const AuthFieldLabel('Confirm new password'),
        const SizedBox(height: 7),
        PasswordField(
          controller: _confirmController,
          hintText: 'Re-enter new password',
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
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
              : const Text('Reset password & log in'),
        ),
      ],
    );
  }
}
