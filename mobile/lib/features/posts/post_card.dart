import 'package:flutter/material.dart';

import '../../api/posts_api.dart';
import '../../models/food_post.dart';
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

    setState(() {
      _isVoting = true;
    });

    try {
      await PostsApi.votePost(
        token: token,
        postId: widget.post.id,
        type: type,
      );

      await widget.onVoteSubmitted();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vote submitted.'),
        ),
      );
    } on PostsApiException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not submit vote.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isVoting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    final confidenceText = post.confidence == null
        ? 'unavailable'
        : '${(post.confidence! * 100).round()}%';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              post.foodName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(post.location),
            const SizedBox(height: 8),
            Text('Status: ${post.status}'),
            const SizedBox(height: 4),
            Text('Confidence: $confidenceText'),
            const SizedBox(height: 8),
            Text(
              'Still here: ${post.presentVotes} · Gone: ${post.goneVotes}',
            ),
            if (post.badges.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: post.badges
                    .map(
                      (badge) => Chip(
                        label: Text(badge),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isVoting ? null : () => _vote('present'),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Still here'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isVoting ? null : () => _vote('gone'),
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Gone'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}