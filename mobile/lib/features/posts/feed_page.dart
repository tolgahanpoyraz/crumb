import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../api/posts_api.dart';
import '../../models/food_post.dart';
import '../../theme/app_theme.dart';
import '../../theme/crumb_wordmark.dart';
import '../../theme/freshness.dart';
import '../auth/auth_session.dart';
import 'post_detail_sheet.dart';
import 'post_format.dart';
import 'post_widgets.dart';

enum _FeedFilter { all, fresh, nearMe }

enum _FeedSort { freshest, newest, endingSoon }

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
  static const LatLng _ucfCenter = LatLng(28.6024, -81.2001);
  static const Duration _pollInterval = Duration(seconds: 45);
  static const List<double> _sheetDetents = [0.14, 0.45, 0.92];

  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  List<FoodPost> _posts = [];
  List<CampusLocation> _locations = [];
  bool _loading = true;
  Object? _error;
  bool _mapReady = false;
  LatLng? _myPosition;
  bool _locating = false;

  static const Map<String, String> _dietaryTagLabels = {
    'vegetarian': 'Vegetarian',
    'vegan': 'Vegan',
    'halal': 'Halal',
    'kosher': 'Kosher',
    'gluten-free': 'Gluten-free',
  };

  _FeedFilter _filter = _FeedFilter.all;
  _FeedSort _sort = _FeedSort.freshest;
  String _searchQuery = '';
  final Set<String> _selectedDietaryTags = {};

  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _initialLoad();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _refreshFeed());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _searchController.dispose();
    _mapController.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  Future<void> _initialLoad() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        PostsApi.getFeed(),
        PostsApi.getLocations(),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _posts = results[0] as List<FoodPost>;
        _locations = results[1] as List<CampusLocation>;
        _loading = false;
      });
      _fitToLocations();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _refreshFeed() async {
    try {
      final feed = await PostsApi.getFeed();
      if (!mounted) {
        return;
      }
      setState(() => _posts = feed);
    } catch (_) {
      // Polling and pull-to-refresh stay quiet on transient failures.
    }
  }

  List<LatLng> _locationPoints() {
    final points = <LatLng>[];

    for (final location in _locations) {
      final lat = location.latitude;
      final lng = location.longitude;
      if (lat != null && lng != null) {
        points.add(LatLng(lat, lng));
      }
    }

    if (points.isEmpty) {
      for (final post in _posts) {
        final lat = post.location.latitude;
        final lng = post.location.longitude;
        if (lat != null && lng != null) {
          points.add(LatLng(lat, lng));
        }
      }
    }

    return points;
  }

  void _fitToLocations() {
    if (!_mapReady) {
      return;
    }

    final points = _locationPoints();
    if (points.isEmpty) {
      _mapController.move(_ucfCenter, 15);
      return;
    }
    if (points.length == 1) {
      _mapController.move(points.first, 16);
      return;
    }

    _mapController.fitCamera(
      CameraFit.coordinates(
        coordinates: points,
        padding: const EdgeInsets.all(70),
        maxZoom: 17,
      ),
    );
  }

  Future<void> _onLocateTap() async {
    if (_locating) {
      return;
    }
    setState(() => _locating = true);
    final found = await _acquirePosition();
    if (!mounted) {
      return;
    }
    setState(() => _locating = false);

    if (found && _myPosition != null) {
      _mapController.move(_myPosition!, 16);
    } else {
      _fitToLocations();
    }
  }

  Future<void> _onNearMeChipTap() async {
    setState(() => _filter = _FeedFilter.nearMe);

    if (_myPosition != null || _locating) {
      return;
    }

    setState(() => _locating = true);
    await _acquirePosition();
    if (!mounted) {
      return;
    }
    setState(() => _locating = false);
  }

  /// Requests permission/service state, then fetches a position into
  /// [_myPosition]. Shows the standard denial SnackBar itself on failure.
  Future<bool> _acquirePosition() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      _showLocationDeniedSnackBar(offerSettings: true);
      return false;
    }
    if (permission == LocationPermission.denied) {
      _showLocationDeniedSnackBar(offerSettings: false);
      return false;
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showLocationDeniedSnackBar(offerSettings: false);
      return false;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) {
        return false;
      }
      setState(() {
        _myPosition = LatLng(position.latitude, position.longitude);
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  void _showLocationDeniedSnackBar({required bool offerSettings}) {
    if (!mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: const Text(
          'Location permission needed to find food near you',
        ),
        action: offerSettings
            ? SnackBarAction(
                label: 'Open settings',
                onPressed: Geolocator.openAppSettings,
              )
            : null,
      ),
    );
  }

  /// Distance in miles from [_myPosition] to a post's location, or null when
  /// either coordinate is unknown.
  double? _distanceMilesTo(FoodPost post) {
    final position = _myPosition;
    final lat = post.location.latitude;
    final lng = post.location.longitude;
    if (position == null || lat == null || lng == null) {
      return null;
    }
    final meters = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      lat,
      lng,
    );
    return meters * 0.000621371;
  }

  List<FoodPost> get _visiblePosts {
    var list = List<FoodPost>.from(_posts);

    final query = _searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((post) {
        return post.foodName.toLowerCase().contains(query) ||
            post.location.name.toLowerCase().contains(query);
      }).toList();
    }

    switch (_filter) {
      case _FeedFilter.fresh:
        list = list.where((post) {
          final status = FreshnessStatus.fromApi(post.status);
          return status == FreshnessStatus.fresh ||
              status == FreshnessStatus.likely;
        }).toList();
        break;
      case _FeedFilter.all:
      case _FeedFilter.nearMe:
        break;
    }

    if (_selectedDietaryTags.isNotEmpty) {
      list = list
          .where(
            (post) => _selectedDietaryTags
                .every((tag) => post.dietaryTags.contains(tag)),
          )
          .toList();
    }

    if (_filter == _FeedFilter.nearMe && _myPosition != null) {
      // "Near me" sorts the already-filtered list by distance ascending —
      // it never excludes posts, matching the web dashboard's behavior.
      list.sort((a, b) {
        final aDist = _distanceMilesTo(a) ?? double.infinity;
        final bDist = _distanceMilesTo(b) ?? double.infinity;
        return aDist.compareTo(bDist);
      });
      return list;
    }

    switch (_sort) {
      case _FeedSort.freshest:
        list.sort(
          (a, b) => (b.confidence ?? 0).compareTo(a.confidence ?? 0),
        );
        break;
      case _FeedSort.newest:
        list.sort((a, b) {
          final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate);
        });
        break;
      case _FeedSort.endingSoon:
        list.sort((a, b) {
          final aDate = a.expiresAt ?? DateTime(9999);
          final bDate = b.expiresAt ?? DateTime(9999);
          return aDate.compareTo(bDate);
        });
        break;
    }

    return list;
  }

  void _openDetail(FoodPost post) {
    showPostDetailSheet(
      context,
      post,
      authSession: widget.authSession,
      onRequireLogin: widget.onRequireLogin,
      onPostUpdated: (updated) {
        if (!mounted) {
          return;
        }
        setState(() {
          _posts = [
            for (final p in _posts) if (p.id == updated.id) updated else p,
          ];
        });
      },
      onPostDeleted: (id) {
        if (!mounted) {
          return;
        }
        setState(() {
          _posts = _posts.where((p) => p.id != id).toList();
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Stack(
        children: [
          _buildMap(),
          Positioned(
            top: topInset + 10,
            left: AppTheme.pagePadding,
            right: AppTheme.pagePadding,
            child: _buildTopControls(),
          ),
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.45,
            minChildSize: _sheetDetents.first,
            maxChildSize: _sheetDetents.last,
            snap: true,
            snapSizes: _sheetDetents,
            builder: (context, scrollController) {
              return _buildSheet(scrollController);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    final markers = _buildMarkers();

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _ucfCenter,
        initialZoom: 15,
        minZoom: 13,
        maxZoom: 18,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
        ),
        onMapReady: () {
          _mapReady = true;
          _fitToLocations();
        },
      ),
      children: [
        ColorFiltered(
          // Warm cream multiply so the light basemap sits in the app palette.
          colorFilter: const ColorFilter.mode(
            Color(0xFFFDEEE1),
            BlendMode.multiply,
          ),
          child: TileLayer(
            urlTemplate:
                'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c', 'd'],
            userAgentPackageName: 'com.crumb.mobile',
            tileProvider: NetworkTileProvider(),
          ),
        ),
        MarkerLayer(markers: markers),
        const RichAttributionWidget(
          alignment: AttributionAlignment.bottomLeft,
          attributions: [
            TextSourceAttribution('CARTO'),
            TextSourceAttribution('OpenStreetMap contributors'),
          ],
        ),
      ],
    );
  }

  List<Marker> _buildMarkers() {
    final grouped = <String, List<FoodPost>>{};

    for (final post in _visiblePosts) {
      final lat = post.location.latitude;
      final lng = post.location.longitude;
      if (lat == null || lng == null) {
        continue;
      }
      grouped.putIfAbsent(post.location.id, () => []).add(post);
    }

    final markers = <Marker>[];

    grouped.forEach((_, posts) {
      posts.sort((a, b) => (b.confidence ?? 0).compareTo(a.confidence ?? 0));
      final top = posts.first;
      final lat = top.location.latitude!;
      final lng = top.location.longitude!;

      markers.add(
        Marker(
          point: LatLng(lat, lng),
          width: 58,
          height: 68,
          alignment: Alignment.topCenter,
          child: _MapPin(
            status: FreshnessStatus.fromApi(top.status),
            count: posts.length,
            onTap: () => _openDetail(top),
          ),
        ),
      );
    });

    final myPosition = _myPosition;
    if (myPosition != null) {
      markers.add(
        Marker(
          point: myPosition,
          width: 30,
          height: 30,
          alignment: Alignment.center,
          child: const _MeMarker(),
        ),
      );
    }

    return markers;
  }

  Widget _buildTopControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _buildSearchBar()),
            const SizedBox(width: 10),
            _LocateButton(onTap: _onLocateTap),
          ],
        ),
        const SizedBox(height: 10),
        _buildFilterChips(),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(17),
        boxShadow: const [
          BoxShadow(
            color: Color(0x733A2A24),
            blurRadius: 26,
            spreadRadius: -12,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.coral,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: CrumbLogoMark()),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                isDense: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: 'Search free food',
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(width: 6),
          _Avatar(session: widget.authSession),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _FilterChip(
            label: 'All',
            selected: _filter == _FeedFilter.all,
            onTap: () => setState(() => _filter = _FeedFilter.all),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Fresh',
            dotColor: FreshnessStatus.fresh.dot,
            selected: _filter == _FeedFilter.fresh,
            onTap: () => setState(() => _filter = _FeedFilter.fresh),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Near me',
            selected: _filter == _FeedFilter.nearMe,
            onTap: _onNearMeChipTap,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: _selectedDietaryTags.isEmpty
                ? 'Dietary'
                : 'Dietary · ${_selectedDietaryTags.length}',
            selected: _selectedDietaryTags.isNotEmpty,
            onTap: _openDietarySheet,
          ),
        ],
      ),
    );
  }

  void _openDietarySheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTheme.sheetRadius)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void toggleTag(String tag, bool selected) {
              setState(() {
                if (selected) {
                  _selectedDietaryTags.add(tag);
                } else {
                  _selectedDietaryTags.remove(tag);
                }
              });
              setSheetState(() {});
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dietary', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _dietaryTagLabels.entries.map((entry) {
                      return FilterChip(
                        label: Text(entry.value),
                        selected: _selectedDietaryTags.contains(entry.key),
                        onSelected: (selected) => toggleTag(entry.key, selected),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Dietary tags come from whoever posted — double-check '
                    'yourself if you have allergies.',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() => _selectedDietaryTags.clear());
                            setSheetState(() {});
                          },
                          child: const Text('Clear'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          child: const Text('Done'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _onGrabberDrag(DragUpdateDetails details) {
    if (!_sheetController.isAttached) {
      return;
    }

    final height = MediaQuery.of(context).size.height;
    _sheetController.jumpTo(
      (_sheetController.size - details.delta.dy / height)
          .clamp(_sheetDetents.first, _sheetDetents.last),
    );
  }

  void _onGrabberDragEnd(DragEndDetails details) {
    if (!_sheetController.isAttached) {
      return;
    }

    final velocity = details.velocity.pixelsPerSecond.dy;
    final size = _sheetController.size;

    double target;
    if (velocity < -300) {
      target = _sheetDetents
          .firstWhere((d) => d > size, orElse: () => _sheetDetents.last);
    } else if (velocity > 300) {
      target = _sheetDetents
          .lastWhere((d) => d < size, orElse: () => _sheetDetents.first);
    } else {
      target = _sheetDetents
          .reduce((a, b) => (size - a).abs() < (size - b).abs() ? a : b);
    }

    _sheetController.animateTo(
      target,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  Widget _buildSheet(ScrollController scrollController) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x663A2A24),
            blurRadius: 44,
            spreadRadius: -20,
            offset: Offset(0, -18),
          ),
        ],
      ),
      child: Column(
        children: [
          // The grabber sits outside the sheet's scrollable, so it needs its
          // own drag handling to move the sheet.
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragUpdate: _onGrabberDrag,
            onVerticalDragEnd: _onGrabberDragEnd,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 10),
              alignment: Alignment.center,
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6D3C6),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          Expanded(
            child: _buildSheetBody(scrollController),
          ),
        ],
      ),
    );
  }

  Widget _buildSheetBody(ScrollController scrollController) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _SheetMessage(
        scrollController: scrollController,
        icon: Icons.cloud_off_rounded,
        title: 'Couldn\'t load the food',
        body: _error.toString(),
        actionLabel: 'Try again',
        onAction: _initialLoad,
      );
    }

    final posts = _visiblePosts;

    if (posts.isEmpty) {
      return _EmptyState(
        scrollController: scrollController,
        onRefresh: _refreshFeed,
      );
    }

    return RefreshIndicator(
      color: AppColors.coral,
      onRefresh: _refreshFeed,
      child: ListView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
        children: [
          _SheetHeader(
            count: posts.length,
            sort: _sort,
            onSortChanged: (value) => setState(() => _sort = value),
          ),
          const SizedBox(height: 14),
          for (final post in posts) ...[
            _FeedPostRow(
              post: post,
              distanceMiles: _distanceMilesTo(post),
              onTap: () => _openDetail(post),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin({
    required this.status,
    required this.count,
    required this.onTap,
  });

  final FreshnessStatus status;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 58,
        height: 68,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Transform.rotate(
                angle: -math.pi / 4,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: status.dot,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(19),
                      topRight: Radius.circular(19),
                      bottomRight: Radius.circular(19),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: status.dot.withValues(alpha: 0.5),
                        blurRadius: 14,
                        spreadRadius: -3,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (count > 1)
              Positioned(
                top: 0,
                right: 2,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A2A24),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// "You are here" map dot: coral fill, white ring, soft shadow — smaller
/// and simpler than the teardrop post pins, matching the web app's
/// `.map-me` / `.mbx-me` marker style.
class _MeMarker extends StatelessWidget {
  const _MeMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: AppColors.coral,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(
            color: AppColors.coral.withValues(alpha: 0.45),
            blurRadius: 16,
            spreadRadius: -2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
    );
  }
}

/// Compact "Hot & fresh right now" list row: thumbnail, status badge, title,
/// "location · X.X mi · time" meta (distance shown when [distanceMiles] is
/// known), chevron. Tapping opens the detail sheet — voting lives there.
class _FeedPostRow extends StatelessWidget {
  const _FeedPostRow({
    required this.post,
    required this.distanceMiles,
    required this.onTap,
  });

  final FoodPost post;
  final double? distanceMiles;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final freshness = FreshnessStatus.fromApi(post.status);
    final imageUrl = PostFormat.imageUrl(post.imageKey);

    return Semantics(
      button: true,
      label: '${post.foodName}, ${freshness.label}',
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                PostThumbnail(
                  imageUrl: imageUrl,
                  width: 60,
                  height: 60,
                  radius: 13,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: StatusBadge(status: freshness, fontSize: 10),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        post.foodName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _meta(post),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.chevron,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _meta(FoodPost post) {
    final distance = distanceMiles;
    return [
      PostFormat.locationName(post),
      if (distance != null) '${distance.toStringAsFixed(1)} mi',
      PostFormat.relativeTime(post.createdAt),
    ].join(' · ');
  }
}

class _LocateButton extends StatelessWidget {
  const _LocateButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(14),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: Color(0x663A2A24),
                blurRadius: 18,
                spreadRadius: -8,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.my_location_rounded,
            color: AppColors.coral,
            size: 21,
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.session});

  final AuthSession session;

  @override
  Widget build(BuildContext context) {
    final name = session.user?['displayName']?.toString().trim();
    final initial = (name != null && name.isNotEmpty)
        ? name.substring(0, 1).toUpperCase()
        : null;

    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: AppColors.appBg,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border, width: 2),
      ),
      alignment: Alignment.center,
      child: initial != null
          ? Text(
              initial,
              style: const TextStyle(
                color: AppColors.coral,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            )
          : const Icon(
              Icons.person_rounded,
              size: 17,
              color: AppColors.textMuted,
            ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.dotColor,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? dotColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.coral : AppColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x99F0653F),
                      blurRadius: 16,
                      spreadRadius: -8,
                      offset: Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dotColor != null && !selected) ...[
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.textSecondary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.count,
    required this.sort,
    required this.onSortChanged,
  });

  final int count;
  final _FeedSort sort;
  final ValueChanged<_FeedSort> onSortChanged;

  static const Map<_FeedSort, String> _labels = {
    _FeedSort.freshest: 'Freshest',
    _FeedSort.newest: 'Newest',
    _FeedSort.endingSoon: 'Ending soon',
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hot & fresh right now',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 2),
              Text.rich(
                TextSpan(
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  children: [
                    TextSpan(
                      text: '$count active',
                      style: const TextStyle(
                        color: AppColors.coral,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: ' spots near campus'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        PopupMenuButton<_FeedSort>(
          initialValue: sort,
          onSelected: onSortChanged,
          position: PopupMenuPosition.under,
          itemBuilder: (context) {
            return [
              for (final entry in _labels.entries)
                PopupMenuItem(value: entry.key, child: Text(entry.value)),
            ];
          },
          child: Container(
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 11),
            decoration: BoxDecoration(
              color: AppColors.appBg,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _labels[sort]!,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 17,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.scrollController,
    required this.onRefresh,
  });

  final ScrollController scrollController;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.coral,
      onRefresh: onRefresh,
      child: ListView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
        children: [
          const SizedBox(height: 10),
          Image.asset('assets/eugene/crying.png', height: 120),
          const SizedBox(height: 16),
          Text(
            'No free food nearby',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 7),
          const Text(
            'New drops show up here the moment someone posts. '
            'Check back soon — or share something you spot.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Eugene ate the last one. Post the next drop?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetMessage extends StatelessWidget {
  const _SheetMessage({
    required this.scrollController,
    required this.icon,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
  });

  final ScrollController scrollController;
  final IconData icon;
  final String title;
  final String body;
  final String actionLabel;
  final Future<void> Function() onAction;

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      children: [
        const SizedBox(height: 12),
        Icon(icon, size: 52, color: AppColors.coral),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          body,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),
        Center(
          child: FilledButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(actionLabel),
          ),
        ),
      ],
    );
  }
}
