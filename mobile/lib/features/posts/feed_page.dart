import 'package:flutter/material.dart';

import '../../api/posts_api.dart';
import '../../models/food_post.dart';
import '../../theme/app_theme.dart';
import '../auth/auth_session.dart';
import 'post_card.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({
    super.key,
    required this.authSession,
    required this.onRequireLogin,
  });

  final AuthSession authSession;
  final VoidCallback onRequireLogin;

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  late Future<List<FoodPost>> postsFuture;

  @override
  void initState() {
    super.initState();
    postsFuture = PostsApi.getFeed();
  }

  Future<void> refreshPosts() async {
    setState(() {
      postsFuture = PostsApi.getFeed();
    });

    await postsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.pagePadding,
                14,
                AppTheme.pagePadding,
                12,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'crumb',
                          style: TextStyle(
                            color: AppColors.coral,
                            fontSize: 29,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.2,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Free food on campus,\n+right now',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ],
                    ),
                  ),
                  _HeaderAction(
                    tooltip: 'Refresh food posts',
                    icon: Icons.refresh_rounded,
                    onPressed: refreshPosts,
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<FoodPost>>(
                future: postsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const _FeedLoading();
                  }

                  if (snapshot.hasError) {
                    return _FeedError(
                      message: snapshot.error.toString(),
                      onRetry: refreshPosts,
                    );
                  }

                  final posts = snapshot.data ?? [];

                  if (posts.isEmpty) {
                    return _EmptyFeed(onRefresh: refreshPosts);
                  }

                  return RefreshIndicator(
                    onRefresh: refreshPosts,
                    color: AppColors.coral,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        AppTheme.pagePadding,
                        8,
                        AppTheme.pagePadding,
                        24,
                      ),
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        return PostCard(
                          post: posts[index],
                          authSession: widget.authSession,
                          onRequireLogin: widget.onRequireLogin,
                          onVoteSubmitted: refreshPosts,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(17),
        boxShadow: AppTheme.softShadow,
      ),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, color: AppColors.coral),
        padding: const EdgeInsets.all(14),
      ),
    );
  }
}

class _FeedLoading extends StatelessWidget {
  const _FeedLoading();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppTheme.pagePadding,
        8,
        AppTheme.pagePadding,
        24,
      ),
      itemCount: 2,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return Container(
          height: 330,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          ),
          child: const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.coral,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 54),
          Container(
            width: 88,
            height: 88,
            margin: const EdgeInsets.symmetric(horizontal: 86),
            decoration: const BoxDecoration(
              color: AppColors.coralSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lunch_dining_rounded,
              size: 42,
              color: AppColors.coral,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'No crumbs yet',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'When someone shares free food on campus, it will show up here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.cocoaMuted),
          ),
          const SizedBox(height: 20),
          Center(
            child: OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Check again'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedError extends StatelessWidget {
  const _FeedError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 54),
        const Icon(
          Icons.cloud_off_rounded,
          size: 58,
          color: AppColors.coral,
        ),
        const SizedBox(height: 18),
        Text(
          'Couldn\'t load the food',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.cocoaMuted),
        ),
        const SizedBox(height: 20),
        Center(
          child: FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ),
      ],
    );
  }
}
