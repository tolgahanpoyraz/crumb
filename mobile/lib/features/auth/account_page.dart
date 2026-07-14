import 'package:flutter/material.dart';

import '../../api/auth_api.dart';
import '../../theme/app_theme.dart';
import 'auth_session.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({
    super.key,
    required this.authSession,
  });

  final AuthSession authSession;

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoginMode = true;
  bool _obscurePassword = true;
  String? _message;
  String? _error;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _message = null;
      _error = null;
    });

    try {
      if (_isLoginMode) {
        await widget.authSession.login(
          email: _emailController.text,
          password: _passwordController.text,
        );

        setState(() => _message = 'Logged in successfully.');
      } else {
        final message = await widget.authSession.register(
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          email: _emailController.text,
          password: _passwordController.text,
        );

        setState(() {
          _message = message;
          _isLoginMode = true;
        });
      }
    } on AuthApiException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = 'Something went wrong. Please try again.');
    }
  }

  Future<void> _resendVerification() async {
    setState(() {
      _message = null;
      _error = null;
    });

    try {
      final message = await widget.authSession.resendVerification(
        email: _emailController.text,
      );
      setState(() => _message = message);
    } on AuthApiException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = 'Could not resend verification email.');
    }
  }

  void _toggleMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
      _message = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.authSession,
      builder: (context, _) {
        final user = widget.authSession.user;

        if (widget.authSession.isLoggedIn && user != null) {
          return _SignedInAccount(
            user: user,
            isLoading: widget.authSession.isLoading,
            onLogout: widget.authSession.logout,
          );
        }

        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.pagePadding,
                24,
                AppTheme.pagePadding,
                36,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'crumb',
                      style: TextStyle(
                        color: AppColors.coral,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isLoginMode ? 'Welcome back' : 'Join the campus table',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isLoginMode
                        ? 'Sign in to share food and help your campus waste less.'
                        : 'Create an account to post food and vote on what is still available.',
                    style: const TextStyle(color: AppColors.cocoaMuted),
                  ),
                  const SizedBox(height: 30),
                  if (!_isLoginMode) ...[
                    const _SectionLabel('YOUR NAME'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _firstNameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'First name',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _lastNameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Last name',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                  const _SectionLabel('SCHOOL EMAIL'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: 'you@university.edu',
                      prefixIcon: Icon(Icons.mail_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const _SectionLabel('PASSWORD'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        tooltip: _obscurePassword
                            ? 'Show password'
                            : 'Hide password',
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: widget.authSession.isLoading ? null : _submit,
                    child: widget.authSession.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(_isLoginMode ? 'Continue' : 'Create account'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isLoginMode
                            ? 'New to Crumb?'
                            : 'Already have an account?',
                        style: const TextStyle(color: AppColors.cocoaMuted),
                      ),
                      TextButton(
                        onPressed:
                            widget.authSession.isLoading ? null : _toggleMode,
                        child: Text(_isLoginMode ? 'Sign up' : 'Log in'),
                      ),
                    ],
                  ),
                  if (_isLoginMode)
                    Center(
                      child: TextButton(
                        onPressed: widget.authSession.isLoading
                            ? null
                            : _resendVerification,
                        child: const Text('Resend verification email'),
                      ),
                    ),
                  if (_message != null) ...[
                    const SizedBox(height: 16),
                    _FeedbackBanner(
                      message: _message!,
                      icon: Icons.check_circle_outline_rounded,
                      foreground: AppColors.mint,
                      background: AppColors.mintSoft,
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    _FeedbackBanner(
                      message: _error!,
                      icon: Icons.error_outline_rounded,
                      foreground: AppColors.error,
                      background: const Color(0xFFFFE6E2),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SignedInAccount extends StatelessWidget {
  const _SignedInAccount({
    required this.user,
    required this.isLoading,
    required this.onLogout,
  });

  final Map<String, dynamic> user;
  final bool isLoading;
  final Future<void> Function() onLogout;

  String get displayName =>
      user['displayName']?.toString().trim().isNotEmpty == true
          ? user['displayName'].toString().trim()
          : 'Crumb member';

  String get email => user['email']?.toString() ?? '';

  String get initials {
    final words = displayName.split(RegExp(r'\s+'));
    return words.take(2).map((word) => word[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.pagePadding,
            24,
            AppTheme.pagePadding,
            36,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('You', style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 34),
              Center(
                child: Container(
                  width: 118,
                  height: 118,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.mint, width: 4),
                    boxShadow: AppTheme.softShadow,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: AppColors.cocoa,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                displayName,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 5),
              Text(
                email,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.cocoaMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFF866A), AppColors.coral],
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x3DF76543),
                      blurRadius: 24,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.volunteer_activism_rounded,
                      color: Colors.white,
                      size: 38,
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Campus food sharer',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Thanks for helping good food find a home.',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                  boxShadow: AppTheme.softShadow,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(
                        color: AppColors.mintSoft,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified_user_outlined,
                        color: AppColors.mint,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Signed in',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Your account is ready to post and vote.',
                            style: TextStyle(
                              color: AppColors.cocoaMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              OutlinedButton.icon(
                onPressed: isLoading ? null : onLogout,
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Log out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.cocoaMuted,
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({
    required this.message,
    required this.icon,
    required this.foreground,
    required this.background,
  });

  final String message;
  final IconData icon;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: foreground),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
