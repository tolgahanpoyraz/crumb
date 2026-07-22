import 'package:flutter/material.dart';

import '../../api/api_config.dart';
import '../../api/posts_api.dart';
import '../../models/food_post.dart';
import '../../theme/app_theme.dart';
import '../../theme/freshness.dart';
import '../posts/post_detail_sheet.dart';
import 'auth_session.dart';
import 'auth_ui.dart';
import 'change_password_page.dart';
import 'edit_profile_page.dart';
import 'login_page.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key, required this.authSession});

  final AuthSession authSession;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: authSession,
      builder: (context, _) {
        if (authSession.isLoggedIn) {
          return _SignedInAccount(authSession: authSession);
        }

        if (authSession.token != null && authSession.sessionLoadFailed) {
          return _SessionRetry(authSession: authSession);
        }

        return LoginPage(authSession: authSession);
      },
    );
  }
}

class _SessionRetry extends StatelessWidget {
  const _SessionRetry({required this.authSession});

  final AuthSession authSession;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.pagePadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded,
                  color: AppColors.textSecondary, size: 40),
              const SizedBox(height: 14),
              Text(
                "We couldn't reach Crumb",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                'Check your connection and try again.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed:
                    authSession.isLoading ? null : authSession.retryLoad,
                child: authSession.isLoading
                    ? const AuthButtonSpinner()
                    : const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignedInAccount extends StatefulWidget {
  const _SignedInAccount({required this.authSession});

  final AuthSession authSession;

  @override
  State<_SignedInAccount> createState() => _SignedInAccountState();
}

class _SignedInAccountState extends State<_SignedInAccount> {
  late Future<List<FoodPost>> _dropsFuture;

  Map<String, dynamic> get _user => widget.authSession.user ?? const {};
  String get _displayName {
    final name = (_user['displayName'] ?? '').toString().trim();
    return name.isEmpty ? 'Crumb member' : name;
  }

  String get _email => (_user['email'] ?? '').toString();
  String get _userId => (_user['id'] ?? '').toString();
  bool get _verified => _user['verified'] == true;

  @override
  void initState() {
    super.initState();
    _dropsFuture = _loadDrops();
  }

  Future<List<FoodPost>> _loadDrops() async {
    final posts = await PostsApi.getFeed();
    return posts.where((post) => post.authorId == _userId).toList();
  }

  Future<void> _refresh() async {
    final future = _loadDrops();
    setState(() => _dropsFuture = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.pagePadding,
              24,
              AppTheme.pagePadding,
              36,
            ),
            children: [
              Text('You', style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 24),
              _Identity(
                displayName: _displayName,
                email: _email,
                avatarKey: _user['avatarKey']?.toString(),
                avatarVersion: widget.authSession.avatarVersion,
                verified: _verified,
              ),
              const SizedBox(height: 30),
              _SectionHeading(
                title: 'Your drops',
                trailing: FutureBuilder<List<FoodPost>>(
                  future: _dropsFuture,
                  builder: (context, snapshot) {
                    final count = snapshot.data?.length ?? 0;
                    if (count == 0) return const SizedBox.shrink();
                    return Text(
                      '$count live',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.coral,
                          ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<FoodPost>>(
                future: _dropsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const _DropsLoading();
                  }
                  if (snapshot.hasError) {
                    return const _DropsError();
                  }

                  final drops = snapshot.data ?? const [];
                  if (drops.isEmpty) {
                    return const _EmptyDrops();
                  }

                  return Column(
                    children: [
                      for (final post in drops) ...[
                        _DropRow(
                          post: post,
                          onTap: () => showPostDetailSheet(context, post),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 26),
              const _SectionHeading(title: 'Account'),
              const SizedBox(height: 12),
              _AccountRows(authSession: widget.authSession),
            ],
          ),
        ),
      ),
    );
  }
}

class _Identity extends StatelessWidget {
  const _Identity({
    required this.displayName,
    required this.email,
    required this.avatarKey,
    required this.avatarVersion,
    required this.verified,
  });

  final String displayName;
  final String email;
  final String? avatarKey;
  final int avatarVersion;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ProfileAvatar(
          displayName: displayName,
          avatarKey: avatarKey,
          avatarVersion: avatarVersion,
          size: 66,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(displayName, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 3),
              Text(
                email,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (verified) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7F6EE),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified_rounded,
                          color: Color(0xFF2F9D63), size: 13),
                      const SizedBox(width: 4),
                      Text(
                        'Verified',
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: const Color(0xFF2F9D63),
                                ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _DropRow extends StatelessWidget {
  const _DropRow({required this.post, required this.onTap});

  final FoodPost post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = FreshnessStatus.fromApi(post.status);
    final pct = post.confidence == null
        ? null
        : (post.confidence!.clamp(0.0, 1.0) * 100).round();

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Thumbnail(imageKey: post.imageKey),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _StatusPill(
                          status: status,
                          label: pct == null
                              ? status.label
                              : '${status.label} · $pct%',
                        ),
                        const Spacer(),
                        _TimeLeft(expiresAt: post.expiresAt, color: status.dot),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      post.foodName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _metaLine(post),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 11.5,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _Tally(
                          icon: Icons.check_rounded,
                          value: post.presentVotes,
                          color: const Color(0xFF2F9D63),
                        ),
                        const SizedBox(width: 12),
                        _Tally(
                          icon: Icons.close_rounded,
                          value: post.goneVotes,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, color: AppColors.chevron),
            ],
          ),
        ),
      ),
    );
  }

  String _metaLine(FoodPost post) {
    final place = post.location.name;
    final created = post.createdAt;
    if (created == null) {
      return place;
    }
    return '$place · ${_ago(created)}';
  }
}

String _ago(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.imageKey});

  final String? imageKey;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageKey != null && imageKey!.isNotEmpty;

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.panelBg,
        borderRadius: BorderRadius.circular(14),
        image: hasImage
            ? DecorationImage(
                image: NetworkImage('${ApiConfig.imageBaseUrl}/$imageKey'),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: hasImage
          ? null
          : const Icon(Icons.restaurant_rounded,
              color: AppColors.placeholder, size: 24),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status, required this.label});

  final FreshnessStatus status;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: status.badgeBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: status.badgeText,
              fontSize: 10,
            ),
      ),
    );
  }
}

class _TimeLeft extends StatelessWidget {
  const _TimeLeft({required this.expiresAt, required this.color});

  final DateTime? expiresAt;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (expiresAt == null) {
      return const SizedBox.shrink();
    }

    final minutes = expiresAt!.difference(DateTime.now()).inMinutes;
    final label = minutes <= 0 ? 'expired' : '$minutes min';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.schedule_rounded, size: 12, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color),
        ),
      ],
    );
  }
}

class _Tally extends StatelessWidget {
  const _Tally({required this.icon, required this.value, required this.color});

  final IconData icon;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 3),
        Text(
          '$value',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: color,
                fontSize: 12,
              ),
        ),
      ],
    );
  }
}

class _DropsLoading extends StatelessWidget {
  const _DropsLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
    );
  }
}

class _DropsError extends StatelessWidget {
  const _DropsError();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        "Couldn't load your drops. Pull down to try again.",
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

class _EmptyDrops extends StatelessWidget {
  const _EmptyDrops();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 26),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFECD8CB),
          width: 1.5,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Image.asset('assets/eugene/silly.png', width: 88, height: 88),
          const SizedBox(height: 14),
          Text(
            'No drops yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            'Spot free food? Eugene will keep it here until it runs out.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tap ＋ Drop to post your find.')),
              );
            },
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text('Drop your first find'),
          ),
        ],
      ),
    );
  }
}

class _AccountRows extends StatelessWidget {
  const _AccountRows({required this.authSession});

  final AuthSession authSession;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _AccountRow(
            icon: Icons.person_outline_rounded,
            label: 'Edit profile',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => EditProfilePage(authSession: authSession),
              ),
            ),
          ),
          const _RowDivider(),
          _AccountRow(
            icon: Icons.lock_outline_rounded,
            label: 'Change password',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ChangePasswordPage(authSession: authSession),
              ),
            ),
          ),
          const _RowDivider(),
          _AccountRow(
            icon: Icons.logout_rounded,
            label: 'Log out',
            danger: true,
            onTap: authSession.logout,
          ),
        ],
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 1, color: AppColors.border);
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    const dangerColor = Color(0xFFC15A2C);
    final color = danger ? dangerColor : AppColors.textPrimary;

    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 52,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: color,
                        fontWeight:
                            danger ? FontWeight.w600 : FontWeight.w500,
                      ),
                ),
              ),
              if (!danger)
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.chevron),
            ],
          ),
        ),
      ),
    );
  }
}
