import 'package:flutter/material.dart';

import '../../api/posts_api.dart';
import '../auth/auth_session.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({
    super.key,
    required this.authSession,
    required this.onRequireLogin,
    required this.onPostCreated,
  });

  final AuthSession authSession;
  final VoidCallback onRequireLogin;
  final VoidCallback onPostCreated;

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _formKey = GlobalKey<FormState>();
  final _foodNameController = TextEditingController();
  final _locationController = TextEditingController();
  final _badgesController = TextEditingController();

  bool _isSubmitting = false;
  String? _error;
  String? _message;

  @override
  void dispose() {
    _foodNameController.dispose();
    _locationController.dispose();
    _badgesController.dispose();
    super.dispose();
  }

  List<String> _parseBadges(String rawValue) {
    return rawValue
        .split(',')
        .map((badge) => badge.trim())
        .where((badge) => badge.isNotEmpty)
        .toList();
  }

  Future<void> _submitPost() async {
    if (!widget.authSession.isLoggedIn) {
      widget.onRequireLogin();
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final token = widget.authSession.token;

    if (token == null || token.isEmpty) {
      widget.onRequireLogin();
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
      _message = null;
    });

    try {
      await PostsApi.createPost(
        token: token,
        foodName: _foodNameController.text,
        location: _locationController.text,
        badges: _parseBadges(_badgesController.text),
      );

      _foodNameController.clear();
      _locationController.clear();
      _badgesController.clear();

      setState(() {
        _message = 'Food post created.';
      });

      widget.onPostCreated();
    } on PostsApiException catch (error) {
      setState(() {
        _error = error.message;
      });
    } catch (_) {
      setState(() {
        _error = 'Could not create post. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.authSession.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Create Food Post'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Log in to create a post',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'You can browse food posts without an account, but you need to log in before posting.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: widget.onRequireLogin,
                  child: const Text('Log in or sign up'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Food Post'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _foodNameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Food name',
                  hintText: 'Pizza, donuts, sandwiches...',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Food name is required';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  hintText: 'HEC 101, Library lobby...',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Location is required';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _badgesController,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Badges',
                  hintText: 'pizza, dessert, vegan',
                  helperText: 'Separate badges with commas',
                  border: OutlineInputBorder(),
                ),
                onFieldSubmitted: (_) => _submitPost(),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _isSubmitting ? null : _submitPost,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add),
                label: Text(_isSubmitting ? 'Posting...' : 'Post food'),
              ),
              if (_message != null) ...[
                const SizedBox(height: 16),
                Text(
                  _message!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}