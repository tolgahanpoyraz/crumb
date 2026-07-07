import 'package:flutter/material.dart';

import '../auth/auth_session.dart';

class CreatePostPage extends StatelessWidget {
  const CreatePostPage({
    super.key,
    required this.authSession,
    required this.onRequireLogin,
    required this.onPostCreated,
  });

  final AuthSession authSession;
  final VoidCallback onRequireLogin;
  final VoidCallback onPostCreated;

  @override
  Widget build(BuildContext context) {
    if (!authSession.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Create Food Post'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Log in to create a post',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'You can browse food posts without an account, but you need to log in before posting.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: onRequireLogin,
                  child: const Text('Log in or sign up'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Food Post'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_circle_outline, size: 56),
              const SizedBox(height: 16),
              const Text(
                'Create post coming soon',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This page is a placeholder. The form will eventually create a new free food post.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onPostCreated,
                child: const Text('Back to feed'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}