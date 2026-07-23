import 'package:flutter/material.dart';

import 'features/auth/account_page.dart';
import 'features/auth/auth_session.dart';
import 'features/auth/login_page.dart';
import 'features/posts/create_post_page.dart';
import 'features/posts/feed_page.dart';
import 'theme/app_theme.dart';

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
  // 0 = Map (feed), 2 = You (account). 1 (Drop) is an action, not a page.
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

  void _openDrop() {
    if (!widget.authSession.isLoggedIn) {
      _goToLogin();
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => CreatePostPage(
          authSession: widget.authSession,
          onRequireLogin: _goToLogin,
          onPostCreated: _handlePostCreated,
        ),
      ),
    );
  }

  void _handlePostCreated() {
    Navigator.of(context).pop();

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
        if (!widget.authSession.isLoggedIn) {
          return LoginPage(authSession: widget.authSession);
        }

        return Scaffold(
          body: IndexedStack(
            index: _selectedIndex == 0 ? 0 : 1,
            children: [
              FeedPage(
                key: ValueKey(_feedReloadVersion),
                authSession: widget.authSession,
                onRequireLogin: _goToLogin,
                onOpenDrop: _openDrop,
              ),
              AccountPage(
                authSession: widget.authSession,
              ),
            ],
          ),
          bottomNavigationBar: _CrumbNavigationBar(
            selectedIndex: _selectedIndex,
            onDropSelected: _openDrop,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
        );
      },
    );
  }
}

class _CrumbNavigationBar extends StatelessWidget {
  const _CrumbNavigationBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.onDropSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onDropSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(
          top: BorderSide(color: Color(0xFFF4E6DD)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: Row(
            children: [
              Expanded(
                child: _NavigationItem(
                  label: 'Map',
                  icon: Icons.map_outlined,
                  selectedIcon: Icons.map_rounded,
                  selected: selectedIndex == 0,
                  onTap: () => onDestinationSelected(0),
                ),
              ),
              Expanded(child: _DropItem(onTap: onDropSelected)),
              Expanded(
                child: _NavigationItem(
                  label: 'You',
                  icon: Icons.person_outline_rounded,
                  selectedIcon: Icons.person_rounded,
                  selected: selectedIndex == 2,
                  onTap: () => onDestinationSelected(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.coral : AppColors.inactiveTab;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkResponse(
        onTap: onTap,
        radius: 34,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? selectedIcon : icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DropItem extends StatelessWidget {
  const _DropItem({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Drop free food',
      child: InkResponse(
        onTap: onTap,
        radius: 34,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_rounded,
              color: AppColors.coral,
              size: 24,
            ),
            const SizedBox(height: 4),
            const Text(
              'Drop',
              style: TextStyle(
                color: AppColors.coral,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
