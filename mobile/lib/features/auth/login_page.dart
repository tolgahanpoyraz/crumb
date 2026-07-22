import 'package:flutter/material.dart';

import '../../api/auth_api.dart';
import '../../theme/app_theme.dart';
import 'auth_session.dart';
import 'auth_ui.dart';
import 'create_account_page.dart';
import 'forgot_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.authSession});

  final AuthSession authSession;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _error;
  bool _showVerifyBanner = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _showVerifyBanner = false;
    });

    try {
      await widget.authSession.login(
        email: _emailController.text,
        password: _passwordController.text,
      );
    } on AuthApiException catch (error) {
      setState(() {
        if (error.statusCode == 403) {
          _showVerifyBanner = true;
        } else {
          _error = error.message;
        }
      });
    } catch (_) {
      setState(() => _error = 'Something went wrong. Please try again.');
    }
  }

  Future<void> _resendVerification() async {
    try {
      final message = await widget.authSession.resendVerification(
        email: _emailController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } on AuthApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = widget.authSession.isLoading;

    return AuthScaffold(
      sticker: 'winking.png',
      tagline: "Free food on campus — before it's gone.",
      children: [
        Text('Welcome back', style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 5),
        Text(
          "Log in to see what's fresh near you.",
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (_showVerifyBanner) ...[
          const SizedBox(height: 20),
          _VerifyBanner(onResend: isLoading ? null : _resendVerification),
        ],
        const SizedBox(height: 22),
        const AuthFieldLabel('School email'),
        const SizedBox(height: 7),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          decoration: const InputDecoration(
            hintText: 'you@ucf.edu',
            prefixIcon: Icon(Icons.mail_outline_rounded),
          ),
        ),
        const SizedBox(height: 16),
        AuthFieldLabel(
          'Password',
          trailing: GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ForgotPasswordPage(authSession: widget.authSession),
              ),
            ),
            child: Text(
              'Forgot?',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.coral,
                  ),
            ),
          ),
        ),
        const SizedBox(height: 7),
        PasswordField(
          controller: _passwordController,
          hintText: '••••••••',
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
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
              : const Text('Log in'),
        ),
        const SizedBox(height: 22),
        AuthFooterLink(
          prompt: 'New to Crumb?',
          action: 'Create an account',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => CreateAccountPage(authSession: widget.authSession),
            ),
          ),
        ),
      ],
    );
  }
}

class _VerifyBanner extends StatelessWidget {
  const _VerifyBanner({required this.onResend});

  final VoidCallback? onResend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warnBg,
        border: Border.all(color: AppColors.warnBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.mail_outline_rounded, color: AppColors.warnIcon, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verify your email to log in',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.warnText,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                GestureDetector(
                  onTap: onResend,
                  child: Text(
                    'Check your inbox for the link — resend verification link.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.warnText,
                          fontSize: 12,
                          decoration: TextDecoration.underline,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
