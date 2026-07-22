import 'package:flutter/material.dart';

import 'features/auth/account_page.dart';
import 'features/auth/auth_session.dart';
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
          bottomNavigationBar: _CrumbNavigationBar(
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
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(color: AppColors.creamDeep),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x147E4534),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 76,
          child: Row(
            children: [
              Expanded(
                child: _NavigationItem(
                  label: 'Food',
                  icon: Icons.restaurant_outlined,
                  selectedIcon: Icons.restaurant,
                  selected: selectedIndex == 0,
                  onTap: () => onDestinationSelected(0),
                ),
              ),
              Expanded(
                child: Semantics(
                  button: true,
                  selected: selectedIndex == 1,
                  label: 'Post food',
                  child: Center(
                    child: Transform.translate(
                      offset: const Offset(0, -10),
                      child: Material(
                        color: AppColors.coral,
                        elevation: 0,
                        shadowColor: AppColors.coral,
                        borderRadius: BorderRadius.circular(21),
                        child: InkWell(
                          onTap: () => onDestinationSelected(1),
                          borderRadius: BorderRadius.circular(21),
                          child: Container(
                            width: 62,
                            height: 62,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(21),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x55F76543),
                                  blurRadius: 18,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                              size: 34,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _NavigationItem(
                  label: 'Account',
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
    final color = selected ? AppColors.coral : AppColors.cocoaMuted;

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
            Icon(selected ? selectedIcon : icon, color: color, size: 25),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
