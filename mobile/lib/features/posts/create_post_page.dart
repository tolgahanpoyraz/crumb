import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../api/posts_api.dart';
import '../../models/food_post.dart';
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
  final _locationDetailController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();

  static const Map<String, String> _foodTypes = {
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

  List<CampusLocation> _locations = [];

  String? _selectedFoodType;
  String? _selectedLocationId;

  final Set<String> _selectedDietaryTags = {};

  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;

  bool _isLoadingLocations = true;
  bool _isSubmitting = false;

  String? _locationsError;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  @override
  void dispose() {
    _foodNameController.dispose();
    _locationDetailController.dispose();
    super.dispose();
  }

  Future<void> _loadLocations() async {
    setState(() {
      _isLoadingLocations = true;
      _locationsError = null;
    });

    try {
      final locations = await PostsApi.getLocations();

      locations.sort(
        (first, second) => first.name.toLowerCase().compareTo(
              second.name.toLowerCase(),
            ),
      );

      if (!mounted) return;

      setState(() {
        _locations = locations;
        _isLoadingLocations = false;

        if (locations.isEmpty) {
          _locationsError = 'No campus locations are currently available.';
        }
      });
    } on PostsApiException catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoadingLocations = false;
        _locationsError = error.message;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoadingLocations = false;
        _locationsError = 'Could not load campus locations.';
      });
    }
  }

  String _getImageContentType(XFile image) {
    if (image.mimeType != null && image.mimeType!.isNotEmpty) {
      return image.mimeType!;
    }

    final lowerPath = image.path.toLowerCase();

    if (lowerPath.endsWith('.png')) {
      return 'image/png';
    }

    if (lowerPath.endsWith('.webp')) {
      return 'image/webp';
    }

    if (lowerPath.endsWith('.heic') || lowerPath.endsWith('.heif')) {
      return 'image/heic';
    }

    return 'image/jpeg';
  }

  Future<void> _showPhotoOptions() async {
    if (_isSubmitting) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take photo'),
                subtitle: const Text('Use your device camera'),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from library'),
                subtitle: const Text('Select an existing photo'),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancel'),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 1400,
      );

      if (image == null) {
        return;
      }

      final bytes = await image.readAsBytes();

      if (!mounted) return;

      setState(() {
        _selectedImage = image;
        _selectedImageBytes = bytes;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = source == ImageSource.camera
            ? 'Could not take the photo.'
            : 'Could not select the photo.';
      });
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _selectedImageBytes = null;
      _error = null;
    });
  }

  void _toggleDietaryTag(String tag, bool selected) {
    setState(() {
      if (selected) {
        _selectedDietaryTags.add(tag);
      } else {
        _selectedDietaryTags.remove(tag);
      }
    });
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

    final selectedFoodType = _selectedFoodType;
    final selectedLocationId = _selectedLocationId;

    if (selectedFoodType == null || selectedLocationId == null) {
      setState(() {
        _error = 'Choose a food type and campus location.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      String? imageKey;

      if (_selectedImage != null && _selectedImageBytes != null) {
        imageKey = await PostsApi.uploadImageBytes(
          token: token,
          bytes: _selectedImageBytes!,
          contentType: _getImageContentType(_selectedImage!),
        );
      }

      await PostsApi.createPost(
        token: token,
        foodName: _foodNameController.text,
        type: selectedFoodType,
        locationId: selectedLocationId,
        dietaryTags: _selectedDietaryTags.toList(),
        locationDetail: _locationDetailController.text,
        imageKey: imageKey,
      );

      if (!mounted) return;

      _foodNameController.clear();
      _locationDetailController.clear();
      _formKey.currentState?.reset();

      setState(() {
        _selectedFoodType = null;
        _selectedLocationId = null;
        _selectedDietaryTags.clear();
        _selectedImage = null;
        _selectedImageBytes = null;
      });

      widget.onPostCreated();
    } on PostsApiException catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = 'Could not create the food post. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Widget _buildLocationField() {
    if (_isLoadingLocations) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
            SizedBox(width: 12),
            Text('Loading campus locations...'),
          ],
        ),
      );
    }

    if (_locationsError != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.error,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _locationsError!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _loadLocations,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: _selectedLocationId,
      decoration: const InputDecoration(
        labelText: 'Campus location',
        border: OutlineInputBorder(),
      ),
      items: _locations
          .map(
            (location) => DropdownMenuItem<String>(
              value: location.id,
              child: Text(location.name),
            ),
          )
          .toList(),
      onChanged: _isSubmitting
          ? null
          : (value) {
              setState(() {
                _selectedLocationId = value;
              });
            },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Campus location is required';
        }

        return null;
      },
    );
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
                const Icon(
                  Icons.lock_outline,
                  size: 48,
                ),
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
                enabled: !_isSubmitting,
                decoration: const InputDecoration(
                  labelText: 'Food name',
                  hintText: 'Leftover pizza, sandwiches, donuts...',
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
              DropdownButtonFormField<String>(
                initialValue: _selectedFoodType,
                decoration: const InputDecoration(
                  labelText: 'Food type',
                  border: OutlineInputBorder(),
                ),
                items: _foodTypes.entries
                    .map(
                      (entry) => DropdownMenuItem<String>(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                    )
                    .toList(),
                onChanged: _isSubmitting
                    ? null
                    : (value) {
                        setState(() {
                          _selectedFoodType = value;
                        });
                      },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Food type is required';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 12),
              _buildLocationField(),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationDetailController,
                textInputAction: TextInputAction.done,
                enabled: !_isSubmitting,
                maxLength: 256,
                decoration: const InputDecoration(
                  labelText: 'Specific location',
                  hintText: 'Room 101, second floor lounge...',
                  helperText: 'Optional',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Dietary tags',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _dietaryTagLabels.entries
                    .map(
                      (entry) => FilterChip(
                        label: Text(entry.value),
                        selected: _selectedDietaryTags.contains(entry.key),
                        onSelected: _isSubmitting
                            ? null
                            : (selected) {
                                _toggleDietaryTag(
                                  entry.key,
                                  selected,
                                );
                              },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _isSubmitting ? null : _showPhotoOptions,
                icon: const Icon(
                  Icons.add_photo_alternate_outlined,
                ),
                label: Text(
                  _selectedImage == null ? 'Add photo' : 'Change photo',
                ),
              ),
              if (_selectedImageBytes != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    _selectedImageBytes!,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 4),
                TextButton.icon(
                  onPressed: _isSubmitting ? null : _removeImage,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remove photo'),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _isSubmitting ||
                        _isLoadingLocations ||
                        _locationsError != null
                    ? null
                    : _submitPost,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.add),
                label: Text(
                  _isSubmitting ? 'Posting...' : 'Post food',
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
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