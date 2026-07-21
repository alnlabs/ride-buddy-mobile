import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:ridebuddy/services/routing_service.dart';
import 'package:ridebuddy/theme/app_theme.dart';

/// Map with markers + driving route polylines.
///
/// Always resolves a finite width/height (critical on Flutter web) and fits
/// markers/routes once the map reports ready.
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
    this.fitToMarkers = true,
    this.fitPadding = const EdgeInsets.all(28),
    this.fitMaxZoom = 14,
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
  /// When true (default), camera fits markers / selected route after map ready.
  final bool fitToMarkers;
  final EdgeInsets fitPadding;
  final double fitMaxZoom;

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
  late final MapController _controller;
  bool _mapReady = false;
  bool _tileError = false;
  int _tileLayerKey = 0;
  int _sourceIndex = 0;
  int _tileFailStreak = 0;
  int _fitGeneration = 0;
  Size? _lastLaidOutSize;

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
    (
      url: 'https://tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
      fallback: 'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
      credit: '© OpenStreetMap · HOT',
    ),
  ];

  bool get _shouldFit =>
      widget.fitToMarkers &&
      (widget.markers.length >= 2 ||
          widget.routes.isNotEmpty ||
          widget.polylines.any((p) => p.points.length >= 2));

  @override
  void initState() {
    super.initState();
    _controller = MapController();
  }

  @override
  void didUpdateWidget(covariant OsmMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final contentChanged = oldWidget.routes != widget.routes ||
        oldWidget.selectedRouteIndex != widget.selectedRouteIndex ||
        oldWidget.markers != widget.markers ||
        oldWidget.polylines != widget.polylines ||
        oldWidget.center != widget.center ||
        oldWidget.height != widget.height ||
        oldWidget.expand != widget.expand;
    if (!contentChanged) return;

    if (_shouldFit) {
      _scheduleFit();
    } else if (oldWidget.center != widget.center) {
      _safeMove(widget.center, widget.zoom);
    }
  }

  void _onMapReady() {
    _mapReady = true;
    if (_shouldFit) {
      _scheduleFit();
    } else {
      _safeMove(widget.center, widget.zoom);
    }
  }

  void _scheduleFit() {
    final gen = ++_fitGeneration;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || gen != _fitGeneration) return;
      _fitContent(attempt: 0);
    });
  }

  void _safeMove(LatLng center, double zoom) {
    if (!_mapReady || !mounted) return;
    try {
      _controller.move(center, zoom);
    } catch (_) {}
  }

  EdgeInsets _safePadding(double mapW, double mapH) {
    final pad = widget.fitPadding;
    final maxH = (mapH * 0.18).clamp(6.0, 36.0);
    final maxW = (mapW * 0.18).clamp(6.0, 36.0);
    return EdgeInsets.only(
      left: pad.left.clamp(0, maxW),
      right: pad.right.clamp(0, maxW),
      top: pad.top.clamp(0, maxH),
      bottom: pad.bottom.clamp(0, maxH),
    );
  }

  void _fitContent({required int attempt}) {
    if (!mounted || !_mapReady) return;

    double mapW;
    double mapH;
    try {
      final size = _controller.camera.nonRotatedSize;
      mapW = size.x;
      mapH = size.y;
    } catch (_) {
      if (attempt < 8) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _fitContent(attempt: attempt + 1);
        });
      }
      return;
    }

    if (mapW <= 2 || mapH <= 2) {
      if (attempt < 8) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _fitContent(attempt: attempt + 1);
        });
      }
      return;
    }

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

    if (points.isEmpty) {
      _safeMove(widget.center, widget.zoom);
      return;
    }
    if (points.length == 1) {
      _safeMove(points.first, widget.zoom);
      return;
    }

    try {
      final bounds = LatLngBounds.fromPoints(points);
      // Degenerate bounds (same point twice) — just center.
      if ((bounds.north - bounds.south).abs() < 1e-8 && (bounds.east - bounds.west).abs() < 1e-8) {
        _safeMove(points.first, widget.zoom);
        return;
      }
      _controller.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: _safePadding(mapW, mapH),
          maxZoom: widget.fitMaxZoom,
        ),
      );
    } catch (_) {
      _safeMove(points[points.length ~/ 2], widget.zoom);
    }
  }

  void _onTileError() {
    _tileFailStreak++;
    if (_tileFailStreak >= 3) {
      _tileFailStreak = 0;
      if (!mounted) return;
      setState(() {
        _tileError = true;
        _sourceIndex = (_sourceIndex + 1) % _sources.length;
        _tileLayerKey++;
      });
    } else if (!_tileError && mounted) {
      setState(() => _tileError = true);
    }
  }

  void _retryTiles() {
    setState(() {
      _tileError = false;
      _tileFailStreak = 0;
      _sourceIndex = (_sourceIndex + 1) % _sources.length;
      _tileLayerKey++;
    });
  }

  List<Polyline> _routePolylines() {
    if (widget.routes.isEmpty) return widget.polylines;
    final out = <Polyline>[];
    for (var i = 0; i < widget.routes.length; i++) {
      if (i == widget.selectedRouteIndex) continue;
      out.add(Polyline(
        points: widget.routes[i].points,
        color: AppTheme.inkMuted.withValues(alpha: 0.45),
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
    return [...out, ...widget.polylines];
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fallbackH = widget.height;
        final h = widget.expand
            ? (constraints.maxHeight.isFinite && constraints.maxHeight > 0
                ? constraints.maxHeight
                : fallbackH)
            : fallbackH;
        final w = constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;

        // Never mount FlutterMap at zero size — blank maps on web.
        if (h < 40 || w < 40) {
          return SizedBox(
            width: w.isFinite ? w : double.infinity,
            height: h < 40 ? fallbackH : h,
            child: const ColoredBox(color: Color(0xFFE8F1FF)),
          );
        }

        final laidOut = Size(w, h);
        if (_lastLaidOutSize != laidOut) {
          final prev = _lastLaidOutSize;
          _lastLaidOutSize = laidOut;
          // Parent resized (common with Expanded / keyboard / web) — refit.
          if (prev != null && _mapReady && _shouldFit) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _scheduleFit();
            });
          }
        }

        final source = _sources[_sourceIndex];
        return SizedBox(
          width: w,
          height: h,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.expand ? 16 : 12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: Color(0xFFE8F1FF)),
                FlutterMap(
                  mapController: _controller,
                  options: MapOptions(
                    initialCenter: widget.center,
                    initialZoom: widget.zoom,
                    onTap: widget.onTap,
                    onMapReady: _onMapReady,
                    backgroundColor: const Color(0xFFE8F1FF),
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
                        headers: const <String, String>{
                          'User-Agent': 'RideBuddy/1.0 (com.alnlabs.ridebuddy; +https://alnlabs.com)',
                        },
                      ),
                      maxZoom: 19,
                      errorTileCallback: (tile, error, stackTrace) => _onTileError(),
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
                if (_tileError)
                  Positioned(
                    left: 8,
                    right: 8,
                    bottom: 8,
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.82),
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Map tiles unavailable — tap Retry',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
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
          ),
        );
      },
    );
  }
}
