import 'package:flutter/material.dart';

import '../../api/users_api.dart';
import '../../theme/app_theme.dart';
import '../../theme/reputation.dart';
import '../auth/auth_session.dart';
import '../auth/auth_ui.dart';
import 'tier_badge.dart';

const _trackColor = Color(0xFFF0E0D6);
const _meTint = Color(0xFFFFF2EC);

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key, required this.authSession});

  final AuthSession authSession;

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  late Future<Leaderboard> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Leaderboard> _load() {
    final token = widget.authSession.token ?? '';
    return UsersApi.getLeaderboard(token: token);
  }

  void _retry() {
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScaffold(
      title: 'Top droppers',
      child: FutureBuilder<Leaderboard>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _Loading();
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return _ErrorState(onRetry: _retry);
          }

          return _Body(
            data: snapshot.data!,
            currentUserId: (widget.authSession.user?['id'] ?? '').toString(),
          );
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.data, required this.currentUserId});

  final Leaderboard data;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StandingCard(me: data.me),
        const SizedBox(height: 18),
        if (data.entries.isEmpty)
          const _EmptyState()
        else
          _TopList(entries: data.entries, currentUserId: currentUserId),
        const SizedBox(height: 18),
        const Text(
          'Points from confirmed drops and honest votes · last 7 days',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _StandingCard extends StatelessWidget {
  const _StandingCard({required this.me});

  final LeaderboardMe me;

  @override
  Widget build(BuildContext context) {
    final tier = ReputationTier.fromLevel(me.tier);
    final progress = tierProgressFor(me.reputation, tier, tier.nextThreshold);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.panelBg,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TierBadge(tier: tier),
              const Spacer(),
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  children: [
                    TextSpan(
                      text: '${me.reputation}',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontSize: 18, color: AppColors.textPrimary),
                    ),
                    const TextSpan(text: ' crumbs'),
                  ],
                ),
              ),
            ],
          ),
          if (progress.atTop) ...[
            const SizedBox(height: 12),
            Text(
              '${ReputationTier.goldenCroissant.glyph} Top of the batch',
              style: const TextStyle(
                color: Color(0xFF9A6B2F),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ] else ...[
            const SizedBox(height: 14),
            _ProgressBar(fraction: progress.fraction),
            const SizedBox(height: 7),
            Text(
              progress.label ?? '',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 12),
          _StandingMeta(me: me),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.fraction});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 8,
        color: _trackColor,
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: fraction.clamp(0.0, 1.0),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.coralLight, AppColors.coral],
              ),
              borderRadius: BorderRadius.all(Radius.circular(999)),
            ),
          ),
        ),
      ),
    );
  }
}

class _StandingMeta extends StatelessWidget {
  const _StandingMeta({required this.me});

  final LeaderboardMe me;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        children: [
          TextSpan(
            text: '${me.weeklyPoints}',
            style: const TextStyle(
              color: AppColors.coral,
              fontWeight: FontWeight.w700,
            ),
          ),
          const TextSpan(text: ' this week'),
          if (me.rank != null) TextSpan(text: ' · ranked #${me.rank}'),
        ],
      ),
    );
  }
}

class _TopList extends StatelessWidget {
  const _TopList({required this.entries, required this.currentUserId});

  final List<LeaderboardEntry> entries;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final entry in entries) ...[
          _LeaderRow(entry: entry, isMe: entry.userId == currentUserId),
          const SizedBox(height: 4),
        ],
      ],
    );
  }
}

class _LeaderRow extends StatelessWidget {
  const _LeaderRow({required this.entry, required this.isMe});

  final LeaderboardEntry entry;
  final bool isMe;

  static const _rankGold = Color(0xFFB8860F);
  static const _rankSilver = Color(0xFF8A8A92);
  static const _rankBronze = Color(0xFFA06B3C);

  Color get _rankColor {
    switch (entry.rank) {
      case 1:
        return _rankGold;
      case 2:
        return _rankSilver;
      case 3:
        return _rankBronze;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tier = ReputationTier.fromLevel(entry.tier);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isMe ? _meTint : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '${entry.rank}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 14,
                    color: _rankColor,
                  ),
            ),
          ),
          const SizedBox(width: 11),
          ProfileAvatar(
            displayName: entry.displayName,
            avatarKey: entry.avatarKey,
            size: 34,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    entry.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (entry.tier >= 1) ...[
                  const SizedBox(width: 7),
                  TierBadge(tier: tier, small: true),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${entry.weeklyPoints}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 26),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFECD8CB), width: 1.5),
      ),
      child: Column(
        children: [
          Image.asset('assets/eugene/munching.png', width: 88, height: 88),
          const SizedBox(height: 14),
          Text(
            'No confirmed drops this week yet — be the first.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
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

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Icon(Icons.wifi_off_rounded,
              color: AppColors.textSecondary, size: 36),
          const SizedBox(height: 14),
          Text(
            "Couldn't load the leaderboard",
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
            onPressed: onRetry,
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}
