import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../api/posts_api.dart';
import '../../models/food_post.dart';
import '../../theme/app_theme.dart';
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
  bool _isPickingImage = false;

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
    } catch (error, stackTrace) {
      debugPrint('Could not load campus locations: $error');
      debugPrintStack(stackTrace: stackTrace);

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
    if (_isSubmitting || _isPickingImage) {
      return;
    }

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      useSafeArea: true,
      builder: (bottomSheetContext) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take photo'),
              subtitle: const Text('Use your device camera'),
              onTap: () {
                Navigator.pop(
                  bottomSheetContext,
                  ImageSource.camera,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from library'),
              subtitle: const Text('Select an existing photo'),
              onTap: () {
                Navigator.pop(
                  bottomSheetContext,
                  ImageSource.gallery,
                );
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
        );
      },
    );

    if (!mounted || source == null) {
      return;
    }

    await Future<void>.delayed(
      const Duration(milliseconds: 250),
    );

    if (!mounted) {
      return;
    }

    await _pickImage(source);
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_isPickingImage) {
      return;
    }

    _isPickingImage = true;

    try {
      debugPrint('Opening image picker with source: $source');

      final image = await _imagePicker.pickImage(
        source: source,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 75,
        maxWidth: 1400,
      );

      debugPrint('Image picker returned: ${image?.path}');

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
    } on PlatformException catch (error, stackTrace) {
      debugPrint(
        'Image picker PlatformException: '
        '${error.code} - ${error.message}',
      );
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      String message;

      switch (error.code) {
        case 'camera_access_denied':
        case 'camera_access_denied_without_prompt':
        case 'camera_access_restricted':
          message =
              'Camera access is disabled. Enable camera access for this app in iPhone Settings.';
          break;

        case 'photo_access_denied':
          message =
              'Photo library access is disabled. Enable photo access for this app in iPhone Settings.';
          break;

        case 'already_active':
          message =
              'The camera or photo picker is already opening. Close it and try again.';
          break;

        default:
          message = source == ImageSource.camera
              ? 'Could not open the camera: ${error.message ?? error.code}'
              : 'Could not open the photo library: ${error.message ?? error.code}';
      }

      setState(() {
        _error = message;
      });
    } catch (error, stackTrace) {
      debugPrint('Unexpected image picker error: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _error = source == ImageSource.camera
            ? 'Could not open the camera.'
            : 'Could not select the photo.';
      });
    } finally {
      _isPickingImage = false;
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
    } catch (error, stackTrace) {
      debugPrint('Could not create food post: $error');
      debugPrintStack(stackTrace: stackTrace);

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
            Expanded(
              child: Text('Loading campus locations...'),
            ),
          ],
        ),
      );
    }

    if (_locationsError != null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFE6E2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _locationsError!,
              style: const TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
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
      isExpanded: true,
      menuMaxHeight: 350,
      decoration: const InputDecoration(
        labelText: 'Campus location',
        prefixIcon: Icon(Icons.location_on_outlined),
      ),
      selectedItemBuilder: (context) {
        return _locations.map((location) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Text(
              location.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList();
      },
      items: _locations.map((location) {
        return DropdownMenuItem<String>(
          value: location.id,
          child: Text(
            location.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: _isSubmitting
          ? null
          : (value) {
              setState(() {
                _selectedLocationId = value;
                _error = null;
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

  Widget _buildPhotoPicker() {
    if (_selectedImageBytes != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.memory(
              _selectedImageBytes!,
              height: 230,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            right: 12,
            top: 12,
            child: Row(
              children: [
                _PhotoAction(
                  tooltip: 'Change photo',
                  icon: Icons.edit_outlined,
                  onPressed:
                      _isSubmitting || _isPickingImage
                          ? null
                          : _showPhotoOptions,
                ),
                const SizedBox(width: 8),
                _PhotoAction(
                  tooltip: 'Remove photo',
                  icon: Icons.delete_outline_rounded,
                  onPressed:
                      _isSubmitting || _isPickingImage ? null : _removeImage,
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Semantics(
      button: true,
      label: 'Add a food photo',
      child: InkWell(
        onTap:
            _isSubmitting || _isPickingImage ? null : _showPhotoOptions,
        borderRadius: BorderRadius.circular(24),
        child: CustomPaint(
          painter: _DashedRoundedRectPainter(
            color: const Color(0x8CB98A7A),
            radius: 24,
          ),
          child: Container(
            height: 210,
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 29,
                  backgroundColor: AppColors.coralLight,
                  child: Icon(
                    Icons.add_a_photo_outlined,
                    color: AppColors.coral,
                    size: 29,
                  ),
                ),
                SizedBox(height: 14),
                Text(
                  'Add a food photo',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Take a photo or choose from your library',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.authSession.isLoggedIn) {
      return Scaffold(
        body: SafeArea(
          bottom: false,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: const BoxDecoration(
                      color: AppColors.coralLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_outline_rounded,
                      color: AppColors.coral,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Log in to share food',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'You can browse without an account, but you need to log in before posting.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: widget.onRequireLogin,
                    child: const Text('Log in or sign up'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('New drop'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.pagePadding,
          8,
          AppTheme.pagePadding,
          36,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPhotoPicker(),
              const SizedBox(height: 26),
              const _FormSectionLabel('WHAT IS IT?'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _foodNameController,
                textInputAction: TextInputAction.next,
                enabled: !_isSubmitting,
                decoration: const InputDecoration(
                  labelText: 'Food name or description',
                  hintText: 'e.g. Leftover pizza — 6 boxes',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Food name is required';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 22),
              const _FormSectionLabel('TYPE'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _foodTypes.entries.map((entry) {
                  return ChoiceChip(
                    label: Text(entry.value),
                    selected: _selectedFoodType == entry.key,
                    onSelected: _isSubmitting
                        ? null
                        : (selected) {
                            setState(() {
                              _selectedFoodType =
                                  selected ? entry.key : null;
                              _error = null;
                            });
                          },
                  );
                }).toList(),
              ),
              const SizedBox(height: 22),
              const _FormSectionLabel('WHERE?'),
              const SizedBox(height: 8),
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
                  prefixIcon: Icon(Icons.pin_drop_outlined),
                ),
              ),
              const SizedBox(height: 8),
              const _FormSectionLabel(
                'DIETARY TAGS · OPTIONAL',
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _dietaryTagLabels.entries
                    .map(
                      (entry) => FilterChip(
                        label: Text(entry.value),
                        selected:
                            _selectedDietaryTags.contains(entry.key),
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
              const SizedBox(height: 26),
              FilledButton.icon(
                onPressed: _isSubmitting ||
                        _isPickingImage ||
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
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.lunch_dining_rounded,
                      ),
                label: Text(
                  _isSubmitting ? 'Posting...' : 'Post free food',
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE6E2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
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

class _FormSectionLabel extends StatelessWidget {
  const _FormSectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.65,
      ),
    );
  }
}

class _PhotoAction extends StatelessWidget {
  const _PhotoAction({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: AppColors.coral,
        ),
      ),
    );
  }
}

class _DashedRoundedRectPainter extends CustomPainter {
  const _DashedRoundedRectPainter({
    required this.color,
    required this.radius,
  });

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(radius),
        ),
      );

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const dashLength = 6.0;
    const gapLength = 5.0;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;

      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(
            distance,
            distance + dashLength,
          ),
          paint,
        );

        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(
    covariant _DashedRoundedRectPainter oldDelegate,
  ) {
    return oldDelegate.color != color ||
        oldDelegate.radius != radius;
  }
}