import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../data/navigation_service.dart';

class MapView extends StatefulWidget {
  final LatLng position;
  final double heading;
  final bool isMoving;
  final double speed;
  final String currentStreet;
  final double tripDistance;
  final List<LatLng> trail;
  final ValueChanged<List<LatLng>>? onRouteSet;

  const MapView({
    super.key,
    required this.position,
    required this.heading,
    required this.isMoving,
    required this.speed,
    required this.currentStreet,
    required this.tripDistance,
    required this.trail,
    this.onRouteSet,
  });

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  late final MapController _mapController;
  bool _showSearch = false;
  final _searchController = TextEditingController();
  List<SearchResult> _searchResults = [];
  bool _searching = false;

  // Navigation state
  NavigationRoute? _activeRoute;
  bool _navigating = false;
  int _currentStepIndex = 0;
  LatLng? _tappedDestination;
  bool _loadingRoute = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void didUpdateWidget(MapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Always try to move map when position changes (even slightly)
    final oldP = oldWidget.position;
    final newP = widget.position;
    if ((oldP.latitude - newP.latitude).abs() > 0.000001 ||
        (oldP.longitude - newP.longitude).abs() > 0.000001) {
      try {
        _mapController.move(widget.position, _mapController.camera.zoom);
      } catch (_) {}

      if (_navigating && _activeRoute != null) {
        _updateNavStep();
      }
    }
  }

  void _updateNavStep() {
    if (_activeRoute == null) return;
    final steps = _activeRoute!.steps;
    if (_currentStepIndex >= steps.length - 1) return;

    final nextStep = steps[_currentStepIndex + 1];
    final dist = const Distance().as(LengthUnit.Meter, widget.position, nextStep.location);
    if (dist < 30) {
      setState(() => _currentStepIndex++);
      if (_currentStepIndex >= steps.length - 1) {
        // Arrived
        setState(() {
          _navigating = false;
          _activeRoute = null;
        });
      }
    }
  }

  Future<void> _navigateToPoint(LatLng dest) async {
    setState(() { _loadingRoute = true; _tappedDestination = dest; });
    final route = await NavigationService.getRoute(widget.position, dest);
    if (route != null && mounted) {
      setState(() {
        _activeRoute = route;
        _navigating = true;
        _currentStepIndex = 0;
        _loadingRoute = false;
        _tappedDestination = null;
      });
      widget.onRouteSet?.call(route.polyline);
    } else if (mounted) {
      setState(() { _loadingRoute = false; _tappedDestination = null; });
    }
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _searching = true);
    final results = await NavigationService.searchPlace(query);
    if (mounted) {
      setState(() {
        _searchResults = results;
        _searching = false;
      });
    }
  }

  Future<void> _startNavigation(SearchResult dest) async {
    setState(() {
      _showSearch = false;
      _searchResults = [];
      _searchController.clear();
    });

    final route = await NavigationService.getRoute(widget.position, dest.location);
    if (route != null && mounted) {
      setState(() {
        _activeRoute = route;
        _navigating = true;
        _currentStepIndex = 0;
      });
      widget.onRouteSet?.call(route.polyline);
    }
  }

  void _cancelNavigation() {
    setState(() {
      _navigating = false;
      _activeRoute = null;
      _currentStepIndex = 0;
    });
  }

  IconData _getManeuverIcon(String maneuver) {
    if (maneuver.contains('left')) return Icons.turn_left;
    if (maneuver.contains('right')) return Icons.turn_right;
    if (maneuver.contains('slight-left')) return Icons.turn_slight_left;
    if (maneuver.contains('slight-right')) return Icons.turn_slight_right;
    if (maneuver == 'roundabout') return Icons.roundabout_left;
    if (maneuver == 'arrive') return Icons.flag;
    return Icons.arrow_upward;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Map
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: widget.position,
            initialZoom: 16,
            onLongPress: (tapPos, latlng) {
              setState(() => _tappedDestination = latlng);
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}@2x.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'com.dashboard.tesla_dashboard',
              maxZoom: 20,
            ),
            // Route polyline
            if (_activeRoute != null)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _activeRoute!.polyline,
                    color: const Color(0xFF3B82F6),
                    strokeWidth: 6,
                  ),
                ],
              ),
            // GPS trail (when not navigating)
            if (!_navigating && widget.trail.length > 1)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: widget.trail,
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.5),
                    strokeWidth: 3,
                  ),
                ],
              ),
            // Car marker
            MarkerLayer(
              markers: [
                Marker(
                  point: widget.position,
                  width: 44,
                  height: 44,
                  child: Transform.rotate(
                    angle: widget.heading * pi / 180,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF3B82F6),
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF3B82F6).withValues(alpha: 0.4), blurRadius: 12, spreadRadius: 3),
                        ],
                      ),
                      child: const Icon(Icons.navigation, color: Colors.white, size: 20),
                    ),
                  ),
                ),
                // Destination marker
                if (_activeRoute != null)
                  Marker(
                    point: _activeRoute!.polyline.last,
                    width: 36,
                    height: 36,
                    child: const Icon(Icons.location_on, color: Color(0xFFEF4444), size: 36),
                  ),
                // Tapped destination marker
                if (_tappedDestination != null && !_navigating)
                  Marker(
                    point: _tappedDestination!,
                    width: 36,
                    height: 36,
                    child: const Icon(Icons.location_on, color: Color(0xFFEF4444), size: 36),
                  ),
              ],
            ),
          ],
        ),

        // ===== Navigation HUD =====
        if (_navigating && _activeRoute != null)
          _buildNavCard()
        else if (!_showSearch)
          _buildDefaultTopBar(),

        // Search overlay
        if (_showSearch)
          _buildSearchOverlay(),

        // Tapped destination confirmation
        if (_tappedDestination != null && !_navigating && !_showSearch)
          Positioned(
            bottom: 60, left: 10, right: 10,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 12)],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.location_on, color: Color(0xFFEF4444), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Navigate here?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                        Text(
                          '${_tappedDestination!.latitude.toStringAsFixed(5)}, ${_tappedDestination!.longitude.toStringAsFixed(5)}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _tappedDestination = null),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.close, size: 18, color: Color(0xFF6B7280)),
                    ),
                  ),
                  GestureDetector(
                    onTap: _loadingRoute ? null : () => _navigateToPoint(_tappedDestination!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: _loadingRoute
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Go', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Bottom info
        _buildBottomBar(),

        // Search button (when not searching and not navigating)
        if (!_showSearch && !_navigating)
          Positioned(
            top: 60,
            right: 10,
            child: GestureDetector(
              onTap: () => setState(() => _showSearch = true),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
                ),
                child: const Icon(Icons.search, color: Color(0xFF3B82F6), size: 22),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNavCard() {
    final step = _activeRoute!.steps[_currentStepIndex];
    final nextStep = _currentStepIndex + 1 < _activeRoute!.steps.length
        ? _activeRoute!.steps[_currentStepIndex + 1]
        : null;

    final distToNext = nextStep != null
        ? const Distance().as(LengthUnit.Meter, widget.position, nextStep.location)
        : 0.0;

    final remainingDist = _activeRoute!.totalDistance;
    final eta = widget.speed > 3
        ? (remainingDist / (widget.speed / 3.6)).round()
        : 0;
    final etaTime = DateTime.now().add(Duration(seconds: eta));
    final etaStr = '${etaTime.hour.toString().padLeft(2, '0')}:${etaTime.minute.toString().padLeft(2, '0')}';

    return Positioned(
      top: 10, left: 10, right: 10,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 2))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFF3B82F6), borderRadius: BorderRadius.circular(10)),
                  child: Icon(_getManeuverIcon(nextStep?.maneuver ?? step.maneuver), color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        distToNext > 1000
                            ? '${(distToNext / 1000).toStringAsFixed(1)} km'
                            : '${distToNext.toInt()} m',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                      ),
                      Text(
                        step.instruction.isNotEmpty ? step.instruction : 'Continue straight',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(etaStr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF3B82F6))),
                    Text(
                      remainingDist > 1000
                          ? '${(remainingDist / 1000).toStringAsFixed(1)} km'
                          : '${remainingDist.toInt()} m',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _cancelNavigation,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Color(0xFFEF4444), size: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultTopBar() {
    return Positioned(
      top: 10, left: 10, right: 10,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFF3B82F6), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.navigation, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.currentStreet.isNotEmpty ? widget.currentStreet : 'GPS Active',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
                  ),
                  Text(
                    '${widget.position.latitude.toStringAsFixed(5)}, ${widget.position.longitude.toStringAsFixed(5)}',
                    style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchOverlay() {
    return Positioned(
      top: 0, left: 0, right: 0, bottom: 0,
      child: Container(
        color: Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() { _showSearch = false; _searchResults = []; }),
                      child: const Icon(Icons.arrow_back, color: Color(0xFF374151)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Search destination...',
                          hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                          filled: true,
                          fillColor: const Color(0xFFF3F4F6),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          suffixIcon: _searching
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.search, color: Color(0xFF3B82F6)),
                                  onPressed: () => _search(_searchController.text),
                                ),
                        ),
                        onSubmitted: _search,
                      ),
                    ),
                  ],
                ),
              ),
              // Results
              Expanded(
                child: _searchResults.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search, size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 8),
                            Text(
                              'Search for a place',
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final result = _searchResults[index];
                          return ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.location_on, color: Color(0xFF3B82F6), size: 20),
                            ),
                            title: Text(result.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              result.displayName,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                              maxLines: 2, overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text('Go', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                            onTap: () => _startNavigation(result),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Positioned(
      bottom: 10, left: 10, right: 10,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _InfoItem(label: 'Speed', value: '${widget.speed.toInt()} km/h'),
            Container(width: 1, height: 24, color: const Color(0xFFE5E7EB)),
            _InfoItem(label: 'Trip', value: '${widget.tripDistance.toStringAsFixed(1)} km'),
            Container(width: 1, height: 24, color: const Color(0xFFE5E7EB)),
            _InfoItem(label: 'Heading', value: '${widget.heading.toInt()}°'),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
        Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF9CA3AF))),
      ],
    );
  }
}
