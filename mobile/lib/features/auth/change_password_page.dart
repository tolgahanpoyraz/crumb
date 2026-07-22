import 'package:flutter/material.dart';

import '../../api/auth_api.dart';
import 'auth_session.dart';
import 'auth_ui.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key, required this.authSession});

  final AuthSession authSession;

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  String? _error;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);

    if (_newController.text != _confirmController.text) {
      setState(() => _error = 'New passwords do not match.');
      return;
    }

    try {
      await widget.authSession.changePassword(
        currentPassword: _currentController.text,
        newPassword: _newController.text,
      );
      if (!mounted) return;
      Navigator.of(context).maybePop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated.')),
      );
    } on AuthApiException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = 'Something went wrong. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.authSession,
      builder: (context, _) {
        final isLoading = widget.authSession.isLoading;

        return SettingsScaffold(
          title: 'Change password',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Pick something you don't use elsewhere.",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              const AuthFieldLabel('Current password'),
              const SizedBox(height: 7),
              PasswordField(
                controller: _currentController,
                hintText: 'Enter current password',
                autofillHints: const [AutofillHints.password],
              ),
              const SizedBox(height: 16),
              const AuthFieldLabel('New password'),
              const SizedBox(height: 7),
              PasswordField(
                controller: _newController,
                hintText: 'Create a new password',
                autofillHints: const [AutofillHints.newPassword],
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              PasswordStrengthMeter(password: _newController.text),
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
              const SizedBox(height: 28),
              Row(
                children: [
                  OutlinedButton(
                    onPressed:
                        isLoading ? null : () => Navigator.of(context).maybePop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: isLoading ? null : _submit,
                      child: isLoading
                          ? const AuthButtonSpinner()
                          : const Text('Update password'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
