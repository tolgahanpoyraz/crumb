import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../api/auth_api.dart';
import '../../theme/app_theme.dart';
import 'auth_session.dart';
import 'auth_ui.dart';
import 'verify_email_page.dart';

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key, required this.authSession});

  final AuthSession authSession;

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _agreed = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _agreed &&
      _nameController.text.trim().isNotEmpty &&
      _emailController.text.trim().isNotEmpty &&
      _passwordController.text.isNotEmpty;

  Future<void> _submit() async {
    setState(() => _error = null);

    final email = _emailController.text.trim();

    try {
      await widget.authSession.register(
        displayName: _nameController.text,
        email: email,
        password: _passwordController.text,
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => VerifyEmailPage(
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
      sticker: 'waving.png',
      tagline: "Eugene's saving you a seat.",
      showBack: true,
      variant: AuthHeaderVariant.green,
      children: [
        Text('Join Crumb', style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 5),
        Text(
          'Share leftovers, snag free food, waste less.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        const AuthFieldLabel('What should we call you?'),
        const SizedBox(height: 7),
        TextField(
          controller: _nameController,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.words,
          autofillHints: const [AutofillHints.name],
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'Your display name',
            prefixIcon: Icon(Icons.person_outline_rounded),
          ),
        ),
        const SizedBox(height: 14),
        const AuthFieldLabel('School email'),
        const SizedBox(height: 7),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'you@ucf.edu',
            prefixIcon: const Icon(Icons.mail_outline_rounded),
            suffixIcon: const _EduChip(),
            suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          ),
        ),
        const SizedBox(height: 14),
        const AuthFieldLabel('Password'),
        const SizedBox(height: 7),
        PasswordField(
          controller: _passwordController,
          hintText: 'Create a password',
          autofillHints: const [AutofillHints.newPassword],
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 10),
        PasswordStrengthMeter(password: _passwordController.text),
        const SizedBox(height: 16),
        _GuidelinesCheckbox(
          value: _agreed,
          onChanged: (value) => setState(() => _agreed = value ?? false),
        ),
        if (_error != null) ...[
          const SizedBox(height: 16),
          AuthMessageBanner(message: _error!, isError: true),
        ],
        const SizedBox(height: 18),
        FilledButton(
          onPressed: (!_canSubmit || isLoading) ? null : _submit,
          child: isLoading
              ? const AuthButtonSpinner()
              : const Text('Create account'),
        ),
        const SizedBox(height: 16),
        AuthFooterLink(
          prompt: 'Already have an account?',
          action: 'Log in',
          onTap: () => Navigator.of(context).maybePop(),
        ),
      ],
    );
  }
}

class _EduChip extends StatelessWidget {
  const _EduChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE7F6EE),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '.edu ✓',
        style: GoogleFonts.hankenGrotesk(
          color: const Color(0xFF4FB783),
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _GuidelinesCheckbox extends StatelessWidget {
  const _GuidelinesCheckbox({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: value,
                onChanged: onChanged,
                activeColor: AppColors.coral,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'I agree to the ',
                      style: GoogleFonts.hankenGrotesk(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextSpan(
                      text: 'Community Guidelines',
                      style: GoogleFonts.hankenGrotesk(
                        color: AppColors.coral,
                        fontSize: 12.5,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(
                      text: ' — real food, real locations, no waste.',
                      style: GoogleFonts.hankenGrotesk(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
