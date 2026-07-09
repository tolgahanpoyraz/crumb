import 'package:flutter/material.dart';

import 'features/auth/account_page.dart';
import 'features/auth/auth_session.dart';
import 'features/posts/create_post_page.dart';
import 'features/posts/feed_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.authSession,
  });

  final AuthSession authSession;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  int _feedReloadVersion = 0;

  void _goToLogin() {
    setState(() {
      _selectedIndex = 2;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please log in or sign up to continue.'),
      ),
    );
  }

  void _goToCreatePost() {
    if (!widget.authSession.isLoggedIn) {
      _goToLogin();
      return;
    }

    setState(() {
      _selectedIndex = 1;
    });
  }

  void _handlePostCreated() {
    setState(() {
      _feedReloadVersion++;
      _selectedIndex = 0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Food post created.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.authSession,
      builder: (context, _) {
        final pages = [
          FeedPage(
            key: ValueKey(_feedReloadVersion),
            authSession: widget.authSession,
            onRequireLogin: _goToLogin,
            onCreatePost: _goToCreatePost,
          ),
          CreatePostPage(
            authSession: widget.authSession,
            onRequireLogin: _goToLogin,
            onPostCreated: _handlePostCreated,
          ),
          AccountPage(
            authSession: widget.authSession,
          ),
        ];

        return Scaffold(
          body: IndexedStack(
            index: _selectedIndex,
            children: pages,
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              final isPostTab = index == 1;

              if (isPostTab && !widget.authSession.isLoggedIn) {
                _goToLogin();
                return;
              }

              setState(() {
                _selectedIndex = index;
              });
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.fastfood_outlined),
                selectedIcon: Icon(Icons.fastfood),
                label: 'Food',
              ),
              NavigationDestination(
                icon: Icon(Icons.add_circle_outline),
                selectedIcon: Icon(Icons.add_circle),
                label: 'Post',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Account',
              ),
            ],
          ),
        );
      },
    );
  }
}