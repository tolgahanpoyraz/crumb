import 'package:flutter/material.dart';

import '../../api/posts_api.dart';
import '../../models/food_post.dart';
import '../auth/auth_session.dart';
import 'post_card.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({
    super.key,
    required this.authSession,
    required this.onRequireLogin,
    required this.onCreatePost,
  });

  final AuthSession authSession;
  final VoidCallback onRequireLogin;
  final VoidCallback onCreatePost;

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
      appBar: AppBar(
        title: const Text('Free Food Feed'),
        actions: [
          IconButton(
            onPressed: refreshPosts,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<FoodPost>>(
        future: postsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return _FeedError(
              message: snapshot.error.toString(),
              onRetry: refreshPosts,
            );
          }

          final posts = snapshot.data ?? [];

          if (posts.isEmpty) {
            return RefreshIndicator(
              onRefresh: refreshPosts,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: const [
                  SizedBox(height: 120),
                  Icon(Icons.fastfood_outlined, size: 64),
                  SizedBox(height: 16),
                  Text(
                    'No food posts yet',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'When someone posts free food on campus, it will show up here.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: refreshPosts,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (!widget.authSession.isLoggedIn) {
            widget.onRequireLogin();
            return;
          }

          widget.onCreatePost();
        },
        icon: const Icon(Icons.add),
        label: const Text('Post food'),
      ),
    );
  }
}

class _FeedError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _FeedError({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Could not load food posts',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}