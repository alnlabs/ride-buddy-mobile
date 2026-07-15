import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:ridebuddy/services/routing_service.dart';
import 'package:ridebuddy/theme/app_theme.dart';

/// Map with markers + selectable driving route alternatives.
class OsmMapView extends StatefulWidget {
  const OsmMapView({
    super.key,
    required this.center,
    this.zoom = 13,
    this.markers = const [],
    this.polylines = const [],
    this.routes = const [],
    this.selectedRouteIndex = 0,
    this.onRouteSelected,
    this.onTap,
    this.height = 220,
    this.expand = false,
    this.interactive = true,
    this.fitToMarkers = false,
  });

  final LatLng center;
  final double zoom;
  final List<Marker> markers;
  final List<Polyline> polylines;
  final List<DriveRoute> routes;
  final int selectedRouteIndex;
  final ValueChanged<int>? onRouteSelected;
  final TapCallback? onTap;
  final double height;
  /// When true, fills the parent instead of using a fixed [height].
  final bool expand;
  final bool interactive;
  final bool fitToMarkers;

  @override
  State<OsmMapView> createState() => _OsmMapViewState();

  static Marker pin(LatLng point, {Color color = AppTheme.brandBlue, IconData icon = Icons.location_on}) {
    return Marker(
      point: point,
      width: 40,
      height: 40,
      child: Icon(icon, color: color, size: 36),
    );
  }
}

class _OsmMapViewState extends State<OsmMapView> {
  final _controller = MapController();
  bool _tileError = false;
  int _tileLayerKey = 0;
  int _sourceIndex = 0;

  static const _sources = [
    (
      url: 'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
      fallback: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      credit: '© OpenStreetMap · © CARTO',
    ),
    (
      url: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      fallback: 'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
      credit: '© OpenStreetMap contributors',
    ),
  ];

  @override
  void didUpdateWidget(covariant OsmMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final shouldFit = widget.fitToMarkers ||
        widget.routes.isNotEmpty ||
        (widget.markers.length >= 2);
    if (shouldFit &&
        (oldWidget.routes != widget.routes ||
            oldWidget.selectedRouteIndex != widget.selectedRouteIndex ||
            oldWidget.markers != widget.markers ||
            oldWidget.center != widget.center)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitContent());
    } else if (oldWidget.center != widget.center && widget.routes.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.move(widget.center, widget.zoom);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitContent());
  }

  void _fitContent() {
    final points = <LatLng>[
      ...widget.markers.map((m) => m.point),
      if (widget.routes.isNotEmpty &&
          widget.selectedRouteIndex >= 0 &&
          widget.selectedRouteIndex < widget.routes.length)
        ...widget.routes[widget.selectedRouteIndex].points
      else
        ...widget.routes.expand((r) => r.points),
      ...widget.polylines.expand((p) => p.points),
    ];
    if (points.length < 2) {
      if (points.isNotEmpty) {
        _controller.move(points.first, widget.zoom);
      }
      return;
    }
    final bounds = LatLngBounds.fromPoints(points);
    _controller.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(40)),
    );
  }

  void _retryTiles() {
    setState(() {
      _tileError = false;
      _sourceIndex = (_sourceIndex + 1) % _sources.length;
      _tileLayerKey++;
    });
  }

  List<Polyline> _routePolylines() {
    if (widget.routes.isEmpty) return widget.polylines;
    final out = <Polyline>[];
    for (var i = 0; i < widget.routes.length; i++) {
      final selected = i == widget.selectedRouteIndex;
      if (selected) continue; // draw selected on top later
      out.add(Polyline(
        points: widget.routes[i].points,
        color: AppTheme.inkMuted.withOpacity(0.45),
        strokeWidth: 4,
      ));
    }
    if (widget.selectedRouteIndex >= 0 && widget.selectedRouteIndex < widget.routes.length) {
      out.add(Polyline(
        points: widget.routes[widget.selectedRouteIndex].points,
        color: AppTheme.brandBlue,
        strokeWidth: 5.5,
      ));
    }
    return [...widget.polylines, ...out];
  }

  @override
  Widget build(BuildContext context) {
    final source = _sources[_sourceIndex];
    final map = ClipRRect(
      borderRadius: BorderRadius.circular(widget.expand ? 16 : 12),
      child: Stack(
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE8F1FF), Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
              ),
            ),
            child: SizedBox.expand(),
          ),
          FlutterMap(
            mapController: _controller,
            options: MapOptions(
              initialCenter: widget.center,
              initialZoom: widget.zoom,
              onTap: widget.onTap,
              backgroundColor: Colors.transparent,
              interactionOptions: InteractionOptions(
                flags: widget.interactive ? InteractiveFlag.all : InteractiveFlag.none,
              ),
            ),
            children: [
              TileLayer(
                key: ValueKey('tiles-$_tileLayerKey-$_sourceIndex'),
                urlTemplate: source.url,
                fallbackUrl: source.fallback,
                userAgentPackageName: 'com.alnlabs.ridebuddy',
                tileProvider: NetworkTileProvider(
                  silenceExceptions: true,
                  headers: <String, String>{
                    'User-Agent': 'RideBuddy/1.0 (com.alnlabs.ridebuddy; +https://alnlabs.com)',
                  },
                ),
                maxZoom: 19,
                errorTileCallback: (tile, error, stackTrace) {
                  if (!_tileError && mounted) setState(() => _tileError = true);
                },
              ),
              PolylineLayer(polylines: _routePolylines()),
              if (widget.markers.isNotEmpty) MarkerLayer(markers: widget.markers),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(source.credit),
                ],
              ),
            ],
          ),
          if (widget.routes.length > 1)
            Positioned(
              left: 8,
              right: 8,
              top: 8,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var i = 0; i < widget.routes.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(
                            widget.routes[i].chipLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: i == widget.selectedRouteIndex ? Colors.white : AppTheme.ink,
                            ),
                          ),
                          selected: i == widget.selectedRouteIndex,
                          selectedColor: AppTheme.brandBlue,
                          backgroundColor: Colors.white.withOpacity(0.92),
                          onSelected: (_) => widget.onRouteSelected?.call(i),
                          showCheckmark: false,
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          if (widget.routes.length == 1)
            Positioned(
              left: 8,
              top: 8,
              child: Material(
                color: Colors.white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    widget.routes.first.chipLabel,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          if (_tileError)
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Material(
                color: Colors.black.withOpacity(0.82),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Map tiles unavailable — check mobile data / Wi‑Fi',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                      TextButton(
                        onPressed: _retryTiles,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    if (widget.expand) {
      return SizedBox.expand(child: map);
    }
    return SizedBox(height: widget.height, child: map);
  }
}
