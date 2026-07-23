import 'package:flutter/material.dart';

import '../../api/posts_api.dart';
import '../../models/food_post.dart';
import '../../theme/app_theme.dart';
import '../../theme/freshness.dart';
import '../../theme/reputation.dart';
import '../auth/auth_session.dart';
import '../reputation/tier_badge.dart';
import 'post_format.dart';
import 'post_widgets.dart';

/// Opens the food-detail modal sheet. Kept as a top-level function so callers
/// across build waves share one entry point; optional params drive voting,
/// own-post delete, and change propagation back to the feed.
Future<void> showPostDetailSheet(
  BuildContext context,
  FoodPost post, {
  AuthSession? authSession,
  VoidCallback? onRequireLogin,
  ValueChanged<FoodPost>? onPostUpdated,
  ValueChanged<String>? onPostDeleted,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: false,
    backgroundColor: AppColors.card,
    builder: (sheetContext) {
      return _PostDetailSheet(
        post: post,
        authSession: authSession,
        onRequireLogin: onRequireLogin,
        onPostUpdated: onPostUpdated,
        onPostDeleted: onPostDeleted,
      );
    },
  );
}

class _PostDetailSheet extends StatefulWidget {
  const _PostDetailSheet({
    required this.post,
    required this.authSession,
    required this.onRequireLogin,
    required this.onPostUpdated,
    required this.onPostDeleted,
  });

  final FoodPost post;
  final AuthSession? authSession;
  final VoidCallback? onRequireLogin;
  final ValueChanged<FoodPost>? onPostUpdated;
  final ValueChanged<String>? onPostDeleted;

  @override
  State<_PostDetailSheet> createState() => _PostDetailSheetState();
}

class _PostDetailSheetState extends State<_PostDetailSheet> {
  late FoodPost _post = widget.post;
  bool _isVoting = false;
  bool _hasVoted = false;
  bool _isDeleting = false;

  bool get _isOwnPost {
    final userId = widget.authSession?.user?['id']?.toString();
    if (userId == null || userId.isEmpty) {
      return false;
    }
    return userId == _post.authorId;
  }

  Future<void> _vote(String type) async {
    final session = widget.authSession;
    final token = session?.token;

    if (session == null || !session.isLoggedIn || token == null || token.isEmpty) {
      widget.onRequireLogin?.call();
      return;
    }

    setState(() => _isVoting = true);

    try {
      final result = await PostsApi.votePost(
        token: token,
        postId: _post.id,
        type: type,
      );

      final updated = _post.copyWith(
        status: result.status,
        confidence: result.confidence,
        presentVotes: result.presentVotes,
        goneVotes: result.goneVotes,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _post = updated;
        _hasVoted = true;
      });
      widget.onPostUpdated?.call(updated);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanks — vote counted.')),
      );
    } on PostsApiException catch (error) {
      if (!mounted) {
        return;
      }
      // 409 = already voted; keep the buttons disabled going forward.
      setState(() => _hasVoted = error.statusCode == 409);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not submit vote.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isVoting = false);
      }
    }
  }

  Future<void> _delete() async {
    final session = widget.authSession;
    final token = session?.token;

    if (session == null || token == null || token.isEmpty) {
      widget.onRequireLogin?.call();
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete this drop?'),
          content: const Text(
            'This removes your post for everyone. This can\'t be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Keep it'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() => _isDeleting = true);

    try {
      await PostsApi.deletePost(token: token, postId: _post.id);

      if (!mounted) {
        return;
      }

      widget.onPostDeleted?.call(_post.id);
      Navigator.of(context).pop();
    } on PostsApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isDeleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isDeleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete the drop.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = _post;
    final freshness = FreshnessStatus.fromApi(post.status);
    final imageUrl = PostFormat.imageUrl(post.imageKey);
    final timeLeft = PostFormat.timeLeft(post.expiresAt);
    final locationDetail = post.locationDetail?.trim();
    final totalVotes = post.presentVotes + post.goneVotes;
    final maxHeight = MediaQuery.of(context).size.height * 0.92;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Hero(imageUrl: imageUrl, timeLeft: timeLeft),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                post.foodName,
                                style:
                                    Theme.of(context).textTheme.headlineMedium,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: StatusBadge(
                                status: freshness,
                                fontSize: 12,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 11,
                                  vertical: 6,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _PosterLine(post: post, isOwnPost: _isOwnPost),
                        const SizedBox(height: 10),
                        _LocationLine(
                          name: PostFormat.locationName(post),
                          detail: locationDetail,
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 7,
                          runSpacing: 7,
                          children: [
                            PostTag(
                              label: PostFormat.foodType(post.type),
                              icon: Icons.restaurant_rounded,
                            ),
                            ...post.dietaryTags.map(
                              (tag) => PostTag(
                                label: PostFormat.dietaryTag(tag),
                                dietary: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _FreshnessSection(
                          status: freshness,
                          confidence: post.confidence,
                          totalVotes: totalVotes,
                        ),
                        const SizedBox(height: 18),
                        if (_isOwnPost)
                          _OwnPostActions(
                            post: post,
                            isDeleting: _isDeleting,
                            onDelete: _isDeleting ? null : _delete,
                          )
                        else
                          _VoteActions(
                            post: post,
                            isVoting: _isVoting,
                            hasVoted: _hasVoted,
                            onVote: _vote,
                          ),
                        _ActivitySection(post: post),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.imageUrl, required this.timeLeft});

  final String? imageUrl;
  final String? timeLeft;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppTheme.sheetRadius),
      ),
      child: Stack(
        children: [
          PostThumbnail(
            imageUrl: imageUrl,
            width: double.infinity,
            height: 196,
            radius: 0,
            iconSize: 46,
          ),
          Positioned(
            top: 10,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Material(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(11),
              child: InkWell(
                borderRadius: BorderRadius.circular(11),
                onTap: () => Navigator.of(context).pop(),
                child: const SizedBox(
                  width: 34,
                  height: 34,
                  child: Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
          if (timeLeft != null)
            Positioned(
              left: 14,
              bottom: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0x8C3A1A12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 13,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Expires in $timeLeft',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PosterLine extends StatelessWidget {
  const _PosterLine({required this.post, required this.isOwnPost});

  final FoodPost post;
  final bool isOwnPost;

  @override
  Widget build(BuildContext context) {
    final time = PostFormat.relativeTime(post.createdAt);
    final avatarUrl = PostFormat.imageUrl(post.authorAvatarKey);

    if (isOwnPost) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF2EC),
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Text(
          'Your drop',
          style: TextStyle(
            color: AppColors.coral,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    final name = post.authorName?.trim();
    final authorTier = post.authorTier;
    final showTier = authorTier != null && authorTier >= 1;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(
            color: Color(0xFFFFD9C9),
            shape: BoxShape.circle,
          ),
          child: avatarUrl == null
              ? const Icon(Icons.person_rounded,
                  size: 17, color: AppColors.coral)
              : Image.network(
                  avatarUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.person_rounded,
                    size: 17,
                    color: AppColors.coral,
                  ),
                ),
        ),
        const SizedBox(width: 9),
        // Wrap with explicit spacing so the badge never clumps against the name
        // or the "· time" fragment, and wraps cleanly on narrow screens.
        Flexible(
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: name == null || name.isEmpty
                ? [
                    Text('Posted $time', style: _metaStyle),
                  ]
                : [
                    RichText(
                      text: TextSpan(
                        style: _metaStyle,
                        children: [
                          const TextSpan(text: 'Posted by '),
                          TextSpan(
                            text: name,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (showTier)
                      TierBadge(
                        tier: ReputationTier.fromLevel(authorTier),
                        small: true,
                      ),
                    Text('· $time', style: _metaStyle),
                  ],
          ),
        ),
      ],
    );
  }

  static const _metaStyle = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
  );
}

class _LocationLine extends StatelessWidget {
  const _LocationLine({required this.name, required this.detail});

  final String name;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final text = [
      name,
      if (detail != null && detail!.isNotEmpty) detail!,
    ].join(' · ');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.location_on_rounded, size: 15, color: AppColors.coral),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _FreshnessSection extends StatelessWidget {
  const _FreshnessSection({
    required this.status,
    required this.confidence,
    required this.totalVotes,
  });

  final FreshnessStatus status;
  final double? confidence;
  final int totalVotes;

  @override
  Widget build(BuildContext context) {
    final value = confidence?.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Freshness',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            if (value != null)
              Text(
                '${(value * 100).round()}%',
                style: TextStyle(
                  color: status.badgeText,
                  fontWeight: FontWeight.w700,
                ),
              )
            else
              Text(
                totalVotes == 1 ? '1 vote' : '$totalVotes votes',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        FreshnessMeter(confidence: value ?? 0, status: status),
      ],
    );
  }
}

class _VoteActions extends StatelessWidget {
  const _VoteActions({
    required this.post,
    required this.isVoting,
    required this.hasVoted,
    required this.onVote,
  });

  final FoodPost post;
  final bool isVoting;
  final bool hasVoted;
  final ValueChanged<String> onVote;

  @override
  Widget build(BuildContext context) {
    final disabled = isVoting || hasVoted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Is it still there?',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 11),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: disabled ? null : () => onVote('present'),
                icon: isVoting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_rounded, size: 18),
                label: Text('Still here ${post.presentVotes}'),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: disabled ? null : () => onVote('gone'),
                icon: const Icon(Icons.close_rounded, size: 16),
                label: Text('It\'s gone ${post.goneVotes}'),
              ),
            ),
          ],
        ),
        if (hasVoted) ...[
          const SizedBox(height: 10),
          const Text(
            'Thanks — you\'ve voted on this drop.',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

class _OwnPostActions extends StatelessWidget {
  const _OwnPostActions({
    required this.post,
    required this.isDeleting,
    required this.onDelete,
  });

  final FoodPost post;
  final bool isDeleting;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _TallyCard(
                count: post.presentVotes,
                label: 'still here',
                bg: FreshnessStatus.fresh.badgeBg,
                countColor: FreshnessStatus.fresh.badgeText,
                labelColor: const Color(0xFF5F9678),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: _TallyCard(
                count: post.goneVotes,
                label: 'gone',
                bg: FreshnessStatus.gone.badgeBg,
                countColor: const Color(0xFFA08B7C),
                labelColor: const Color(0xFFA08B7C),
              ),
            ),
          ],
        ),
        const SizedBox(height: 11),
        const Text(
          'You can\'t vote on your own drop — these are from others.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: onDelete,
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFC15A2C),
            side: const BorderSide(color: Color(0xFFF0D4C8), width: 1.5),
            minimumSize: const Size.fromHeight(50),
          ),
          icon: isDeleting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.delete_outline_rounded, size: 18),
          label: const Text('Delete this drop'),
        ),
      ],
    );
  }
}

class _TallyCard extends StatelessWidget {
  const _TallyCard({
    required this.count,
    required this.label,
    required this.bg,
    required this.countColor,
    required this.labelColor,
  });

  final int count;
  final String label;
  final Color bg;
  final Color countColor;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: countColor,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: labelColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivitySection extends StatelessWidget {
  const _ActivitySection({required this.post});

  final FoodPost post;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.only(top: 15),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ActivityRow(
            dot: FreshnessStatus.fresh.dot,
            label: 'Still here',
            count: post.presentVotes,
          ),
          const SizedBox(height: 9),
          _ActivityRow(
            dot: FreshnessStatus.gone.dot,
            label: 'Gone',
            count: post.goneVotes,
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.dot,
    required this.label,
    required this.count,
  });

  final Color dot;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
        ),
        const SizedBox(width: 9),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          count == 1 ? '1 vote' : '$count votes',
          style: const TextStyle(
            color: AppColors.fieldLabel,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
