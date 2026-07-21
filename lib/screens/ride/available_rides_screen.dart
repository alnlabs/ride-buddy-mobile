import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:ridebuddy/models/models.dart';
import 'package:ridebuddy/providers/ride_hub_focus_provider.dart';
import 'package:ridebuddy/screens/booking/my_trips_screen.dart';
import 'package:ridebuddy/services/api_client.dart';
import 'package:ridebuddy/services/place_label_formatter.dart';
import 'package:ridebuddy/services/ride_repository.dart';
import 'package:ridebuddy/services/routing_service.dart';
import 'package:ridebuddy/theme/app_theme.dart';
import 'package:ridebuddy/widgets/common/comfort_booking.dart';
import 'package:ridebuddy/widgets/common/empty_state.dart';
import 'package:ridebuddy/widgets/common/poster_identity.dart';
import 'package:ridebuddy/widgets/common/ui_kit.dart';
import 'package:ridebuddy/widgets/maps/osm_map_view.dart';
import 'package:ridebuddy/widgets/ride/ride_post_card.dart';

/// After posting a seat request: browse matching rides (map-first).
/// Phone: map + swipe cards. Desktop: map + selectable ride list side-by-side.
class AvailableRidesScreen extends ConsumerStatefulWidget {
  const AvailableRidesScreen({super.key, required this.needId});

  final String needId;

  @override
  ConsumerState<AvailableRidesScreen> createState() => _AvailableRidesScreenState();
}

class _AvailableRidesScreenState extends ConsumerState<AvailableRidesScreen> {
  /// Phone / narrow web below this; desktop split layout at or above.
  static const _desktopBreakpoint = 800.0;
  static const _geo = Distance();

  late Future<_Bundle> _future;
  bool _mapMode = true;
  bool _booking = false;
  String? _selectedRideId;
  PageController? _pageController;
  int _pageIndex = 0;
  final _focusNode = FocusNode();
  final Map<String, DriveRoute> _routesById = {};
  final Map<String, DriveRoute> _walkPickupById = {};
  final Map<String, DriveRoute> _walkDropById = {};
  bool _routesLoading = false;
  RideRequest? _activeNeed;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
    _future = _load();
  }

  @override
  void dispose() {
    _pageController?.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<_Bundle> _load() async {
    final repo = ref.read(rideRepositoryProvider);
    final need = await repo.getNeed(widget.needId);
    final matches = need.status == 'open' ? await repo.needMatches(widget.needId) : <Ride>[];
    return _Bundle(need: need, matches: matches);
  }

  Future<void> _refresh() async {
    _routesById.clear();
    _walkPickupById.clear();
    _walkDropById.clear();
    final next = _load();
    setState(() => _future = next);
    await next;
  }

  Future<void> _openAndRefresh(String location) async {
    await context.push(location);
    if (mounted) await _refresh();
  }

  DriveRoute _straightRoute(Ride r) {
    final from = LatLng(r.originLat, r.originLng);
    final to = LatLng(r.destinationLat, r.destinationLng);
    return DriveRoute(
      points: [from, to],
      distanceMeters: _geo.as(LengthUnit.Meter, from, to),
      durationSeconds: 0,
    );
  }

  DriveRoute? _routeFor(Ride r) {
    final cached = _routesById[r.id];
    if (cached != null) return cached;
    return DriveRoute.fromJsonCoords(
      r.routeGeometry,
      distanceMeters: r.routeDistanceM,
      durationSeconds: r.routeDurationS,
    );
  }

  Future<void> _ensureActiveLayers(Ride? ride, RideRequest need) async {
    if (ride == null) return;
    _activeNeed = need;
    final routing = ref.read(routingServiceProvider);
    final needDrive = !_routesById.containsKey(ride.id) &&
        DriveRoute.fromJsonCoords(
              ride.routeGeometry,
              distanceMeters: ride.routeDistanceM,
              durationSeconds: ride.routeDurationS,
            ) ==
            null;
    final needWalk = !_walkPickupById.containsKey(ride.id) || !_walkDropById.containsKey(ride.id);
    if (!needDrive && !needWalk) {
      // Still seed drive from stored geometry once.
      final stored = DriveRoute.fromJsonCoords(
        ride.routeGeometry,
        distanceMeters: ride.routeDistanceM,
        durationSeconds: ride.routeDurationS,
      );
      if (stored != null && !_routesById.containsKey(ride.id)) {
        setState(() => _routesById[ride.id] = stored);
      }
      return;
    }

    if (_routesLoading) return;
    setState(() => _routesLoading = true);
    try {
      final futures = <Future<void>>[];

      if (!_routesById.containsKey(ride.id)) {
        final stored = DriveRoute.fromJsonCoords(
          ride.routeGeometry,
          distanceMeters: ride.routeDistanceM,
          durationSeconds: ride.routeDurationS,
        );
        if (stored != null) {
          _routesById[ride.id] = stored;
        } else {
          futures.add(() async {
            try {
              final list = await routing.routes(
                LatLng(ride.originLat, ride.originLng),
                LatLng(ride.destinationLat, ride.destinationLng),
              );
              _routesById[ride.id] = list.isNotEmpty ? list.first : _straightRoute(ride);
            } catch (_) {
              _routesById[ride.id] = _straightRoute(ride);
            }
          }());
        }
      }

      if (!_walkPickupById.containsKey(ride.id)) {
        futures.add(() async {
          _walkPickupById[ride.id] = await routing.walkRoute(
            LatLng(need.originLat, need.originLng),
            LatLng(ride.originLat, ride.originLng),
          );
        }());
      }
      if (!_walkDropById.containsKey(ride.id)) {
        futures.add(() async {
          _walkDropById[ride.id] = await routing.walkRoute(
            LatLng(ride.destinationLat, ride.destinationLng),
            LatLng(need.destinationLat, need.destinationLng),
          );
        }());
      }

      await Future.wait(futures);
    } finally {
      if (mounted) setState(() => _routesLoading = false);
    }
  }

  void _scheduleActiveLayers(List<Ride> matches, RideRequest need) {
    if (matches.isEmpty) return;
    final ride = matches[_pageIndex.clamp(0, matches.length - 1)];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ensureActiveLayers(ride, need);
    });
  }

  String _fmtDist(double meters) {
    if (meters < 1000) return '${meters.round()} m';
    final km = meters / 1000;
    return km >= 10 ? '${km.toStringAsFixed(0)} km' : '${km.toStringAsFixed(1)} km';
  }

  /// Walk distance: uses routed foot path when loaded, else straight-line.
  ({String pickup, String drop, double pickupM, double dropM}) _gaps(Ride ride, RideRequest need) {
    final pickupWalk = _walkPickupById[ride.id];
    final dropWalk = _walkDropById[ride.id];
    final pickupM = pickupWalk?.distanceMeters ??
        _geo.as(
          LengthUnit.Meter,
          LatLng(need.originLat, need.originLng),
          LatLng(ride.originLat, ride.originLng),
        );
    final dropM = dropWalk?.distanceMeters ??
        _geo.as(
          LengthUnit.Meter,
          LatLng(ride.destinationLat, ride.destinationLng),
          LatLng(need.destinationLat, need.destinationLng),
        );
    return (
      pickup: _fmtDist(pickupM),
      drop: _fmtDist(dropM),
      pickupM: pickupM,
      dropM: dropM,
    );
  }

  void _syncSelection(List<Ride> matches) {
    if (matches.isEmpty) {
      if (_selectedRideId != null || _pageIndex != 0) {
        setState(() {
          _selectedRideId = null;
          _pageIndex = 0;
        });
      }
      return;
    }
    final idx = matches.indexWhere((r) => r.id == _selectedRideId);
    final nextIdx = idx < 0 ? 0 : idx;
    final nextId = matches[nextIdx].id;
    if (_selectedRideId != nextId || _pageIndex != nextIdx) {
      setState(() {
        _selectedRideId = nextId;
        _pageIndex = nextIdx;
      });
      final c = _pageController;
      if (c != null && c.hasClients && c.page?.round() != nextIdx) {
        c.jumpToPage(nextIdx);
      }
    }
  }

  void _scheduleSync(List<Ride> matches) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncSelection(matches);
    });
  }

  void _selectRide(List<Ride> matches, int index, {bool animatePage = true, RideRequest? need}) {
    if (index < 0 || index >= matches.length) return;
    final id = matches[index].id;
    if (_selectedRideId == id && _pageIndex == index) {
      final n = need ?? _activeNeed;
      if (n != null) _ensureActiveLayers(matches[index], n);
      return;
    }
    setState(() {
      _selectedRideId = id;
      _pageIndex = index;
    });
    final c = _pageController;
    if (animatePage && c != null && c.hasClients) {
      c.animateToPage(
        index,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
    final n = need ?? _activeNeed;
    if (n != null) _ensureActiveLayers(matches[index], n);
  }

  Future<void> _book(Ride ride, RideRequest need) async {
    final proceed = await confirmCompactBookingIfNeeded(
      context,
      preferComfort: need.comfortPreferred,
      rideIsComfort: ride.comfortRide,
    );
    if (!proceed || !mounted) return;

    setState(() => _booking = true);
    try {
      await ref.read(rideRepositoryProvider).book({
        'rideId': ride.id,
        'seatsRequested': need.seatsNeeded,
        'pickupLat': need.originLat,
        'pickupLng': need.originLng,
        'pickupLabel': need.originLabel,
        'dropLat': need.destinationLat,
        'dropLng': need.destinationLng,
        'dropLabel': need.destinationLabel,
      });
      if (!mounted) return;
      bumpRideData(ref);
      ref.invalidate(myTripsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking requested — waiting for host')),
      );
      await _openAndRefresh(
        '/ride/detail/${ride.id}${need.comfortPreferred ? '?preferComfort=1' : ''}',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ref.read(apiClientProvider).messageFrom(e))),
      );
    } finally {
      if (mounted) setState(() => _booking = false);
    }
  }

  String _short(String label, {int max = 28}) => PlaceLabelFormatter.shortenStoredLabel(label);

  @override
  Widget build(BuildContext context) {
    return SkyScaffold(
      appBar: AppBar(
        title: const Text('Available rides'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      child: FutureBuilder<_Bundle>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: SoftPanel(
                child: EmptyState(
                  title: 'Couldn’t load rides',
                  subtitle: ref.read(apiClientProvider).messageFrom(snap.error!),
                  actionLabel: 'Retry',
                  onAction: _refresh,
                ),
              ),
            );
          }

          final bundle = snap.data!;
          final need = bundle.need;
          final matches = bundle.matches;
          final detailQ = need.comfortPreferred ? '?preferComfort=1' : '';
          _scheduleSync(matches);
          _scheduleActiveLayers(matches, need);

          return LayoutBuilder(
            builder: (context, constraints) {
              // Prefer full window width so Chrome desktop always gets the split layout.
              final screenW = MediaQuery.sizeOf(context).width;
              final wide = screenW >= _desktopBreakpoint || constraints.maxWidth >= _desktopBreakpoint;

              return CallbackShortcuts(
                bindings: <ShortcutActivator, VoidCallback>{
                  const SingleActivator(LogicalKeyboardKey.arrowLeft): () {
                    if (matches.isEmpty) return;
                    _selectRide(matches, _pageIndex - 1, need: need);
                  },
                  const SingleActivator(LogicalKeyboardKey.arrowRight): () {
                    if (matches.isEmpty) return;
                    _selectRide(matches, _pageIndex + 1, need: need);
                  },
                  const SingleActivator(LogicalKeyboardKey.arrowUp): () {
                    if (matches.isEmpty) return;
                    _selectRide(matches, _pageIndex - 1, need: need);
                  },
                  const SingleActivator(LogicalKeyboardKey.arrowDown): () {
                    if (matches.isEmpty) return;
                    _selectRide(matches, _pageIndex + 1, need: need);
                  },
                },
                child: Focus(
                  focusNode: _focusNode,
                  autofocus: true,
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(wide ? 24 : 20, 4, wide ? 24 : 20, 0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    matches.isEmpty
                                        ? 'No open rides near your route yet'
                                        : '${matches.length} ride${matches.length == 1 ? '' : 's'} near your route',
                                    style: Theme.of(context).textTheme.titleSmall,
                                  ),
                                  if (matches.isNotEmpty)
                                    Text(
                                      _mapMode
                                          ? (wide
                                              ? 'Select a ride in the list · ← → to switch'
                                              : 'Swipe cards to compare rides')
                                          : 'Pick a ride and request a seat',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                ],
                              ),
                            ),
                            // On wide screens map+list are shown together — toggle is list-only.
                            if (!wide || !_mapMode)
                              _ViewToggle(
                                mapMode: _mapMode,
                                onChanged: (map) => setState(() {
                                  _mapMode = map;
                                  if (map && matches.isNotEmpty) {
                                    _scheduleSync(matches);
                                  }
                                }),
                              )
                            else
                              TextButton.icon(
                                onPressed: () => setState(() => _mapMode = false),
                                icon: const Icon(Icons.view_list_rounded, size: 18),
                                label: const Text('List only'),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _mapMode
                            ? (wide
                                ? _buildDesktopMapView(matches, need, detailQ)
                                : _buildMobileMapView(matches, need, detailQ))
                            : matches.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                                    child: SoftPanel(
                                      child: EmptyState(
                                        title: 'No open rides yet',
                                        subtitle:
                                            'Your request is posted on Ride — hosts nearby can still offer a seat',
                                        icon: Icons.directions_car_outlined,
                                        accent: AppTheme.brandBlue,
                                        actionLabel: 'Back to Ride',
                                        onAction: () => context.go('/ride'),
                                      ),
                                    ),
                                  )
                                : _buildListOnly(matches, need, detailQ, wide: wide),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildListOnly(List<Ride> matches, RideRequest need, String detailQ, {required bool wide}) {
    final list = ListView.builder(
      padding: EdgeInsets.fromLTRB(wide ? 24 : 20, 0, wide ? 24 : 20, 28),
      itemCount: matches.length,
      itemBuilder: (context, i) {
        final r = matches[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: RidePostCard(
            ride: r,
            onTap: () => _openAndRefresh('/ride/detail/${r.id}$detailQ'),
            footer: Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonal(
                onPressed: _booking ? null : () => _book(r, need),
                child: const Text('Request seat'),
              ),
            ),
          ),
        );
      },
    );

    if (!wide) return list;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: list,
      ),
    );
  }

  ({
    List<Marker> markers,
    List<DriveRoute> routes,
    List<Polyline> walkPolylines,
    int selectedRouteIndex,
    LatLng center,
    Ride? selected,
  }) _mapLayers(
    List<Ride> matches,
    RideRequest need,
  ) {
    Ride? selected;
    if (matches.isNotEmpty) {
      selected = matches[_pageIndex.clamp(0, matches.length - 1)];
    }

    final center = selected != null
        ? LatLng(selected.originLat, selected.originLng)
        : LatLng(need.originLat, need.originLng);

    final markers = <Marker>[
      Marker(
        point: LatLng(need.originLat, need.originLng),
        width: 28,
        height: 28,
        child: const _EndpointDot(color: AppTheme.brandBlue, icon: Icons.trip_origin_rounded),
      ),
      Marker(
        point: LatLng(need.destinationLat, need.destinationLng),
        width: 28,
        height: 28,
        child: const _EndpointDot(color: AppTheme.brandOrange, icon: Icons.flag_rounded),
      ),
    ];
    final routes = <DriveRoute>[];
    final walkPolylines = <Polyline>[];
    const selectedRouteIndex = 0;

    final selectedRide = selected;
    if (selectedRide != null) {
      final r = selectedRide;
      markers.add(
        Marker(
          point: LatLng(r.originLat, r.originLng),
          width: 48,
          height: 48,
          alignment: Alignment.bottomCenter,
          child: const Icon(
            Icons.directions_car_filled_rounded,
            color: AppTheme.brandOrange,
            size: 40,
          ),
        ),
      );
      markers.add(
        Marker(
          point: LatLng(r.destinationLat, r.destinationLng),
          width: 36,
          height: 36,
          child: const Icon(Icons.location_on, color: AppTheme.brandOrange, size: 34),
        ),
      );
      routes.add(_routeFor(r) ?? _straightRoute(r));

      final walkPickup = _walkPickupById[r.id];
      final walkDrop = _walkDropById[r.id];
      if (walkPickup != null && walkPickup.points.length >= 2 && walkPickup.distanceMeters >= 12) {
        walkPolylines.add(
          Polyline(
            points: walkPickup.points,
            color: AppTheme.brandBlue.withValues(alpha: 0.9),
            strokeWidth: 3.5,
            pattern: StrokePattern.dashed(segments: const [10, 8]),
          ),
        );
      }
      if (walkDrop != null && walkDrop.points.length >= 2 && walkDrop.distanceMeters >= 12) {
        walkPolylines.add(
          Polyline(
            points: walkDrop.points,
            color: AppTheme.brandOrange.withValues(alpha: 0.9),
            strokeWidth: 3.5,
            pattern: StrokePattern.dashed(segments: const [10, 8]),
          ),
        );
      }
    }

    return (
      markers: markers,
      routes: routes,
      walkPolylines: walkPolylines,
      selectedRouteIndex: selectedRouteIndex,
      center: center,
      selected: selected,
    );
  }

  Widget _mapPane(
    List<Ride> matches,
    RideRequest need, {
    required bool showSideNav,
    bool desktop = false,
  }) {
    final layers = _mapLayers(matches, need);
    return SoftPanel(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            OsmMapView(
              center: layers.center,
              expand: true,
              fitToMarkers: true,
              fitPadding: desktop
                  ? const EdgeInsets.fromLTRB(48, 56, 48, 48)
                  : const EdgeInsets.fromLTRB(40, 48, 40, 40),
              markers: layers.markers,
              routes: layers.routes,
              polylines: layers.walkPolylines,
              selectedRouteIndex: layers.selectedRouteIndex,
            ),
            Positioned(
              left: 10,
              top: 10,
              child: _MapLegend(
                hasRides: matches.isNotEmpty,
                count: matches.length,
                desktop: desktop,
                loadingRoutes: _routesLoading,
              ),
            ),
            if (layers.selected?.poster != null)
              Positioned(
                left: 10,
                right: showSideNav ? 56 : 10,
                bottom: 10,
                child: _MapPosterBanner(
                  poster: layers.selected!.poster!,
                  roleBadge: 'Host',
                ),
              ),
            if (showSideNav && matches.length > 1)
              Positioned(
                right: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _MapNavBtn(
                        icon: Icons.keyboard_arrow_up_rounded,
                        enabled: _pageIndex > 0,
                        tooltip: 'Previous ride',
                        onTap: () => _selectRide(matches, _pageIndex - 1, need: need),
                      ),
                      const SizedBox(height: 6),
                      _MapNavBtn(
                        icon: Icons.keyboard_arrow_down_rounded,
                        enabled: _pageIndex < matches.length - 1,
                        tooltip: 'Next ride',
                        onTap: () => _selectRide(matches, _pageIndex + 1, need: need),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Desktop / wide web: map left + full ride list right (no bottom carousel).
  Widget _buildDesktopMapView(List<Ride> matches, RideRequest need, String detailQ) {
    Ride? selected;
    if (matches.isNotEmpty) {
      selected = matches[_pageIndex.clamp(0, matches.length - 1)];
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: _mapPane(matches, need, showSideNav: false, desktop: true),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 400,
            child: SoftPanel(
              padding: EdgeInsets.zero,
              child: matches.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Your trip on the map',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Hosts nearby can still offer a seat to your request.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const Spacer(),
                          OutlinedButton(
                            onPressed: () => context.go('/ride'),
                            child: const Text('Back to Ride'),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Compare rides',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                              ),
                                IconButton(
                                  tooltip: 'Previous (←)',
                                  onPressed: _pageIndex > 0
                                      ? () => _selectRide(matches, _pageIndex - 1, need: need)
                                      : null,
                                  icon: const Icon(Icons.chevron_left_rounded),
                                ),
                                IconButton(
                                  tooltip: 'Next (→)',
                                  onPressed: _pageIndex < matches.length - 1
                                      ? () => _selectRide(matches, _pageIndex + 1, need: need)
                                      : null,
                                  icon: const Icon(Icons.chevron_right_rounded),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          Expanded(
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                              itemCount: matches.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, i) {
                                final r = matches[i];
                                final g = _gaps(r, need);
                                return _RidePickCard(
                                  ride: r,
                                  selected: i == _pageIndex,
                                  dense: true,
                                  shortOrigin: _short(r.originLabel, max: 40),
                                  shortDest: _short(r.destinationLabel, max: 40),
                                  pickupDist: g.pickup,
                                  dropDist: g.drop,
                                  booking: _booking,
                                  onSelect: () => _selectRide(matches, i, need: need),
                                  onOpen: () => _openAndRefresh('/ride/detail/${r.id}$detailQ'),
                                  onRequest: () => _book(r, need),
                                );
                              },
                            ),
                          ),
                          if (selected != null) ...[
                            const Divider(height: 1),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                              child: Builder(
                                builder: (context) {
                                  final g = _gaps(selected!, need);
                                  return Text(
                                    'Walk to pickup ${g.pickup} · Walk after drop ${g.drop}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  );
                                },
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 52,
                                    child: OutlinedButton(
                                      onPressed: () =>
                                          _openAndRefresh('/ride/detail/${selected!.id}$detailQ'),
                                      child: const Text('Details'),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: SizedBox(
                                    height: 52,
                                    child: FilledButton(
                                      onPressed: _booking ? null : () => _book(selected!, need),
                                      child: _booking
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Text('Request seat'),
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
        ],
      ),
    );
  }

  /// Mobile / narrow: tall map on top + swipeable ride cards under it.
  Widget _buildMobileMapView(List<Ride> matches, RideRequest need, String detailQ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _mapPane(matches, need, showSideNav: true, desktop: false)),
          const SizedBox(height: 10),
          if (matches.isEmpty)
            SoftPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Your From → To is on the map',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Hosts nearby can still offer a seat to your request.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () => context.go('/ride'),
                    child: const Text('Back to Ride'),
                  ),
                ],
              ),
            )
          else ...[
            if (matches.length > 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 6, left: 4, right: 4),
                child: Row(
                  children: [
                    Text('Swipe to compare', style: Theme.of(context).textTheme.bodySmall),
                    const Spacer(),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Previous',
                      onPressed: _pageIndex > 0
                          ? () => _selectRide(matches, _pageIndex - 1, need: need)
                          : null,
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Next',
                      onPressed: _pageIndex < matches.length - 1
                          ? () => _selectRide(matches, _pageIndex + 1, need: need)
                          : null,
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                  ],
                ),
              ),
            SizedBox(
              height: 196,
              child: PageView.builder(
                controller: _pageController,
                itemCount: matches.length,
                onPageChanged: (i) => _selectRide(matches, i, animatePage: false, need: need),
                itemBuilder: (context, i) {
                  final r = matches[i];
                  final active = i == _pageIndex;
                  final g = _gaps(r, need);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: AnimatedScale(
                      scale: active ? 1 : 0.97,
                      duration: const Duration(milliseconds: 180),
                      child: _RidePickCard(
                        ride: r,
                        selected: active,
                        shortOrigin: _short(r.originLabel, max: 32),
                        shortDest: _short(r.destinationLabel, max: 32),
                        pickupDist: g.pickup,
                        dropDist: g.drop,
                        booking: _booking,
                        onSelect: () => _selectRide(matches, i, need: need),
                        onOpen: () => _openAndRefresh('/ride/detail/${r.id}$detailQ'),
                        onRequest: () => _book(r, need),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RidePickCard extends StatelessWidget {
  const _RidePickCard({
    required this.ride,
    required this.shortOrigin,
    required this.shortDest,
    required this.pickupDist,
    required this.dropDist,
    required this.booking,
    required this.onSelect,
    required this.onOpen,
    required this.onRequest,
    this.selected = false,
    this.dense = false,
  });

  final Ride ride;
  final String shortOrigin;
  final String shortDest;
  final String pickupDist;
  final String dropDist;
  final bool booking;
  final bool selected;
  final bool dense;
  final VoidCallback onSelect;
  final VoidCallback onOpen;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppTheme.brandBlue.withValues(alpha: 0.04) : AppTheme.surfaceElevated,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? AppTheme.brandBlue : AppTheme.line,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onSelect,
        onDoubleTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        mouseCursor: SystemMouseCursors.click,
        child: Padding(
          padding: EdgeInsets.fromLTRB(14, dense ? 10 : 12, 14, dense ? 10 : 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.directions_car_filled_rounded,
                    color: selected ? AppTheme.brandOrange : AppTheme.brandBlue,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (ride.poster != null)
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  ride.poster!.displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.brandOrange.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text(
                                  'Host',
                                  style: TextStyle(
                                    color: AppTheme.brandOrange,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        Text(
                          '$shortOrigin → $shortDest',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.inkMuted,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                  FareChip(pricePerSeat: ride.pricePerSeat, compact: true),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${DateFormat.MMMd().add_jm().format(ride.departAt)} · '
                '${ride.availableSeats} seat${ride.availableSeats == 1 ? '' : 's'}'
                '${ride.comfortRide ? ' · Comfort' : ''}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Walk to pickup $pickupDist · Walk after drop $dropDist',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.ink,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (ride.poster != null) ...[
                const SizedBox(height: 10),
                PosterIdentity(
                  poster: ride.poster!,
                  dense: true,
                  maxInterests: 4,
                  showName: false,
                ),
              ],
              if (!dense) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: onOpen,
                          child: const Text('Details'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: FilledButton(
                          onPressed: booking ? null : onRequest,
                          child: booking
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Request seat'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EndpointDot extends StatelessWidget {
  const _EndpointDot({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }
}

class _MapPosterBanner extends StatelessWidget {
  const _MapPosterBanner({
    required this.poster,
    required this.roleBadge,
  });

  final PosterCard poster;
  final String roleBadge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.96),
      elevation: 2,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: PosterIdentity(
          poster: poster,
          roleBadge: roleBadge,
          dense: true,
          maxInterests: 4,
        ),
      ),
    );
  }
}

class _MapLegend extends StatelessWidget {
  const _MapLegend({
    required this.hasRides,
    required this.count,
    this.desktop = false,
    this.loadingRoutes = false,
  });

  final bool hasRides;
  final int count;
  final bool desktop;
  final bool loadingRoutes;

  @override
  Widget build(BuildContext context) {
    final label = !hasRides
        ? 'Your trip on map'
        : loadingRoutes
            ? 'Loading walk & drive…'
            : desktop
                ? '$count rides · dashed = walk'
                : '$count ride${count == 1 ? '' : 's'} · dashed = walk';
    return Material(
      color: Colors.white.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loadingRoutes) ...[
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapNavBtn extends StatelessWidget {
  const _MapNavBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final btn = Material(
      color: Colors.white.withValues(alpha: 0.94),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? onTap : null,
        mouseCursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            icon,
            color: enabled ? AppTheme.brandBlue : AppTheme.inkMuted.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
    if (tooltip == null) return btn;
    return Tooltip(message: tooltip!, child: btn);
  }
}

class _Bundle {
  _Bundle({required this.need, required this.matches});
  final RideRequest need;
  final List<Ride> matches;
}

class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.mapMode, required this.onChanged});

  final bool mapMode;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleBtn(
            icon: Icons.view_list_rounded,
            selected: !mapMode,
            onTap: () => onChanged(false),
          ),
          _ToggleBtn(
            icon: Icons.map_rounded,
            selected: mapMode,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  const _ToggleBtn({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      mouseCursor: SystemMouseCursors.click,
      child: Container(
        width: 36,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppTheme.brandBlue.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(
          icon,
          size: 18,
          color: selected ? AppTheme.brandBlue : AppTheme.inkMuted,
        ),
      ),
    );
  }
}
