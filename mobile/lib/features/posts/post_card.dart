import 'package:flutter/material.dart';

import '../../api/api_config.dart';
import '../../api/posts_api.dart';
import '../../models/food_post.dart';
import '../../theme/app_theme.dart';
import '../../theme/freshness.dart';
import '../auth/auth_session.dart';

class PostCard extends StatefulWidget {
  const PostCard({
    super.key,
    required this.post,
    required this.authSession,
    required this.onRequireLogin,
    required this.onVoteSubmitted,
  });

  final FoodPost post;
  final AuthSession authSession;
  final VoidCallback onRequireLogin;
  final Future<void> Function() onVoteSubmitted;

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _isVoting = false;

  static const Map<String, String> _foodTypeLabels = {
    'pizza': 'Pizza',
    'meal': 'Meal',
    'snacks': 'Snacks',
    'baked-goods': 'Baked goods',
    'drinks': 'Drinks',
    'other': 'Other',
  };

  static const Map<String, String> _dietaryTagLabels = {
    'vegetarian': 'Vegetarian',
    'vegan': 'Vegan',
    'halal': 'Halal',
    'kosher': 'Kosher',
    'gluten-free': 'Gluten-free',
  };

  String? _buildImageUrl(String? imageKey) {
    if (imageKey == null || imageKey.trim().isEmpty) return null;

    final trimmedKey = imageKey.trim();

    if (trimmedKey.startsWith('http://') ||
        trimmedKey.startsWith('https://')) {
      return trimmedKey;
    }

    final baseUrl = ApiConfig.imageBaseUrl.replaceAll(RegExp(r'/$'), '');
    final normalizedKey = trimmedKey.replaceFirst(RegExp(r'^/'), '');
    return '$baseUrl/$normalizedKey';
  }

  String _formatFoodType(String type) {
    return _foodTypeLabels[type] ?? _capitalizeWords(type);
  }

  String _formatDietaryTag(String tag) {
    return _dietaryTagLabels[tag] ?? _capitalizeWords(tag);
  }

  String _capitalizeWords(String value) {
    return value
        .replaceAll('-', ' ')
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map(
          (word) =>
              '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  String _locationName(FoodPost post) {
    final name = post.location.name.trim();
    if (name.isNotEmpty) return name;

    final id = post.location.id.trim();
    if (id.isNotEmpty) return _capitalizeWords(id);

    return 'Unknown location';
  }

  String _relativeTime(DateTime? date) {
    if (date == null) return 'Recently';

    final difference = DateTime.now().difference(date.toLocal());
    if (difference.isNegative || difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${date.toLocal().month}/${date.toLocal().day}';
  }

  Future<void> _vote(String type) async {
    if (!widget.authSession.isLoggedIn) {
      widget.onRequireLogin();
      return;
    }

    final token = widget.authSession.token;
    if (token == null || token.isEmpty) {
      widget.onRequireLogin();
      return;
    }

    setState(() => _isVoting = true);

    try {
      await PostsApi.votePost(
        token: token,
        postId: widget.post.id,
        type: type,
      );
      await widget.onVoteSubmitted();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vote submitted.')),
      );
    } on PostsApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not submit vote.')),
      );
    } finally {
      if (mounted) setState(() => _isVoting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final imageUrl = _buildImageUrl(post.imageKey);
    final locationDetail = post.locationDetail?.trim();
    final freshness = FreshnessStatus.fromApi(post.status);
    final confidence = post.confidence?.clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: AppTheme.softShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              _PostImage(imageUrl: imageUrl),
              Positioned(
                top: 14,
                left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: freshness.badgeBg,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x17000000),
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: freshness.dot,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        freshness.label,
                        style: TextStyle(
                          color: freshness.badgeText,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.foodName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      color: AppColors.coral,
                      size: 19,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        [
                          _locationName(post),
                          if (locationDetail != null && locationDetail.isNotEmpty)
                            locationDetail,
                        ].join(' · '),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _relativeTime(post.createdAt),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    _PostTag(
                      label: _formatFoodType(post.type),
                      icon: Icons.restaurant_rounded,
                    ),
                    ...post.dietaryTags.map(
                      (tag) => _PostTag(label: _formatDietaryTag(tag)),
                    ),
                  ],
                ),
                if (confidence != null) ...[
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Text(
                        'Freshness',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      Text(
                        '${(confidence * 100).round()}%',
                        style: TextStyle(
                          color: freshness.badgeText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  FreshnessMeter(
                    confidence: confidence,
                    status: freshness,
                  ),
                ],
                const SizedBox(height: 18),
                const Text(
                  'Is it still there?',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _isVoting ? null : () => _vote('present'),
                        style: FilledButton.styleFrom(
                          backgroundColor: FreshnessStatus.fresh.dot,
                          disabledBackgroundColor: FreshnessStatus.fresh.badgeBg,
                        ),
                        icon: _isVoting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_rounded),
                        label: Text('Still here ${post.presentVotes}'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isVoting ? null : () => _vote('gone'),
                        icon: const Icon(Icons.close_rounded),
                        label: Text('Gone ${post.goneVotes}'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PostImage extends StatelessWidget {
  const _PostImage({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null) return const _ImagePlaceholder();

    return Image.network(
      imageUrl!,
      width: double.infinity,
      height: 210,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const _ImagePlaceholder(showLoader: true);
      },
      errorBuilder: (_, __, ___) => const _ImagePlaceholder(isError: true),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({
    this.showLoader = false,
    this.isError = false,
  });

  final bool showLoader;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 210,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.coralLight, AppColors.border],
        ),
      ),
      alignment: Alignment.center,
      child: showLoader
          ? const CircularProgressIndicator()
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isError
                      ? Icons.broken_image_outlined
                      : Icons.lunch_dining_rounded,
                  size: 48,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: 8),
                Text(
                  isError ? 'Photo unavailable' : 'Shared campus food',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
    );
  }
}

class _PostTag extends StatelessWidget {
  const _PostTag({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.appBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: AppColors.coral),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
