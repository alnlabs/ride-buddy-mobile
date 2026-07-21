import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:ridebuddy/models/models.dart';
import 'package:ridebuddy/providers/ride_hub_focus_provider.dart';
import 'package:ridebuddy/screens/profile/profile_screen.dart';
import 'package:ridebuddy/services/api_client.dart';
import 'package:ridebuddy/services/place_label_formatter.dart';
import 'package:ridebuddy/services/ride_repository.dart';
import 'package:ridebuddy/services/routing_service.dart';
import 'package:ridebuddy/theme/app_theme.dart';
import 'package:ridebuddy/widgets/common/empty_state.dart';
import 'package:ridebuddy/widgets/common/poster_identity.dart';
import 'package:ridebuddy/widgets/common/ui_kit.dart';
import 'package:ridebuddy/widgets/maps/osm_map_view.dart';
import 'package:ridebuddy/widgets/ride/need_post_card.dart';

/// Host browses co-riders asking for a seat near this open ride (map + list).
class FindCoRidersScreen extends ConsumerStatefulWidget {
  const FindCoRidersScreen({super.key, required this.rideId});

  final String rideId;

  @override
  ConsumerState<FindCoRidersScreen> createState() => _FindCoRidersScreenState();
}

class _FindCoRidersScreenState extends ConsumerState<FindCoRidersScreen> {
  static const _desktopBreakpoint = 800.0;
  static const _geo = Distance();

  late Future<_Bundle> _future;
  Future<_Bundle>? _preparedFor;
  bool _mapMode = true;
  bool _offering = false;
  int _pageIndex = 0;
  String? _selectedNeedId;
  PageController? _pageController;
  final _focusNode = FocusNode();
  DriveRoute? _hostRoute;
  final Map<String, DriveRoute> _walkPickup = {};
  final Map<String, DriveRoute> _walkDrop = {};
  bool _loadingPaths = false;

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
    final ride = await repo.getRide(widget.rideId);
    final matches = ride.status == 'open' ? await repo.rideMatchingNeeds(widget.rideId) : <NeedInboxItem>[];
    return _Bundle(ride: ride, matches: matches);
  }

  void _onBundleReady(Future<_Bundle> future, _Bundle bundle) {
    if (identical(_preparedFor, future)) return;
    _preparedFor = future;
    _syncSelection(bundle.matches);
    if (bundle.matches.isEmpty) return;
    final need = bundle.matches[_pageIndex.clamp(0, bundle.matches.length - 1)].request;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ensurePaths(bundle.ride, need);
    });
  }

  Future<void> _refresh() async {
    _walkPickup.clear();
    _walkDrop.clear();
    _hostRoute = null;
    _preparedFor = null;
    final next = _load();
    setState(() => _future = next);
    await next;
  }

  Future<void> _openAndRefresh(String location) async {
    await context.push(location);
    if (mounted) await _refresh();
  }

  String _short(String label, {int max = 28}) => PlaceLabelFormatter.shortenStoredLabel(label);

  String _fmtDist(double meters) {
    if (meters < 1000) return '${meters.round()} m';
    final km = meters / 1000;
    return km >= 10 ? '${km.toStringAsFixed(0)} km' : '${km.toStringAsFixed(1)} km';
  }

  ({String pickup, String drop}) _gaps(RideRequest need, Ride ride) {
    final pickupM = _walkPickup[need.id]?.distanceMeters ??
        _geo.as(
          LengthUnit.Meter,
          LatLng(need.originLat, need.originLng),
          LatLng(ride.originLat, ride.originLng),
        );
    final dropM = _walkDrop[need.id]?.distanceMeters ??
        _geo.as(
          LengthUnit.Meter,
          LatLng(ride.destinationLat, ride.destinationLng),
          LatLng(need.destinationLat, need.destinationLng),
        );
    return (pickup: _fmtDist(pickupM), drop: _fmtDist(dropM));
  }

  void _syncSelection(List<NeedInboxItem> matches) {
    if (matches.isEmpty) {
      _selectedNeedId = null;
      _pageIndex = 0;
      return;
    }
    final idx = matches.indexWhere((m) => m.request.id == _selectedNeedId);
    final next = idx < 0 ? 0 : idx;
    _selectedNeedId = matches[next].request.id;
    _pageIndex = next;
  }

  void _selectNeed(List<NeedInboxItem> matches, Ride ride, int index, {bool animatePage = true}) {
    if (index < 0 || index >= matches.length) return;
    final id = matches[index].request.id;
    if (_selectedNeedId == id && _pageIndex == index) {
      _ensurePaths(ride, matches[index].request);
      return;
    }
    setState(() {
      _selectedNeedId = id;
      _pageIndex = index;
    });
    final c = _pageController;
    if (animatePage && c != null && c.hasClients) {
      c.animateToPage(index, duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
    }
    _ensurePaths(ride, matches[index].request);
  }

  Future<void> _ensurePaths(Ride ride, RideRequest need) async {
    final routing = ref.read(routingServiceProvider);
    var changed = false;

    if (_hostRoute == null) {
      final stored = DriveRoute.fromJsonCoords(
        ride.routeGeometry,
        distanceMeters: ride.routeDistanceM,
        durationSeconds: ride.routeDurationS,
      );
      if (stored != null) {
        _hostRoute = stored;
        changed = true;
      } else {
        if (!_loadingPaths && mounted) setState(() => _loadingPaths = true);
        try {
          final list = await routing.routes(
            LatLng(ride.originLat, ride.originLng),
            LatLng(ride.destinationLat, ride.destinationLng),
          );
          _hostRoute = list.isNotEmpty
              ? list.first
              : DriveRoute(
                  points: [
                    LatLng(ride.originLat, ride.originLng),
                    LatLng(ride.destinationLat, ride.destinationLng),
                  ],
                  distanceMeters: _geo.as(
                    LengthUnit.Meter,
                    LatLng(ride.originLat, ride.originLng),
                    LatLng(ride.destinationLat, ride.destinationLng),
                  ),
                  durationSeconds: 0,
                );
          changed = true;
        } catch (_) {}
      }
    }

    final needWalk = !_walkPickup.containsKey(need.id) || !_walkDrop.containsKey(need.id);
    if (needWalk) {
      if (!_loadingPaths && mounted) setState(() => _loadingPaths = true);
      try {
        await Future.wait([
          if (!_walkPickup.containsKey(need.id))
            routing
                .walkRoute(
                  LatLng(need.originLat, need.originLng),
                  LatLng(ride.originLat, ride.originLng),
                )
                .then((w) {
              _walkPickup[need.id] = w;
              changed = true;
            }),
          if (!_walkDrop.containsKey(need.id))
            routing
                .walkRoute(
                  LatLng(ride.destinationLat, ride.destinationLng),
                  LatLng(need.destinationLat, need.destinationLng),
                )
                .then((w) {
              _walkDrop[need.id] = w;
              changed = true;
            }),
        ]);
      } catch (_) {}
    }

    if (!mounted) return;
    if (!changed && !_loadingPaths) return;
    setState(() {
      _loadingPaths = false;
      if (changed) _selectedNeedId = need.id;
    });
  }

  Future<void> _offer(NeedInboxItem item) async {
    if (item.alreadyOffered) return;
    setState(() => _offering = true);
    try {
      await ref.read(rideRepositoryProvider).offerSeat(
            requestId: item.request.id,
            rideId: widget.rideId,
          );
      if (!mounted) return;
      bumpRideData(ref);
      ref.invalidate(seatRequestCountProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offer sent — waiting for co-rider')),
      );
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ref.read(apiClientProvider).messageFrom(e))),
      );
    } finally {
      if (mounted) setState(() => _offering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SkyScaffold(
      appBar: AppBar(
        title: const Text('Find co-riders'),
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
                  title: 'Couldn’t load co-riders',
                  subtitle: ref.read(apiClientProvider).messageFrom(snap.error!),
                  actionLabel: 'Retry',
                  onAction: _refresh,
                ),
              ),
            );
          }

          final bundle = snap.data!;
          final ride = bundle.ride;
          final matches = bundle.matches;
          if (snap.connectionState == ConnectionState.done) {
            _onBundleReady(_future, bundle);
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final wide =
                  MediaQuery.sizeOf(context).width >= _desktopBreakpoint || constraints.maxWidth >= _desktopBreakpoint;

              return CallbackShortcuts(
                bindings: {
                  const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
                      _selectNeed(matches, ride, _pageIndex - 1),
                  const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
                      _selectNeed(matches, ride, _pageIndex + 1),
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
                                        ? 'No co-riders near this ride yet'
                                        : '${matches.length} co-rider${matches.length == 1 ? '' : 's'} near your route',
                                    style: Theme.of(context).textTheme.titleSmall,
                                  ),
                                  Text(
                                    '${_short(ride.originLabel)} → ${_short(ride.destinationLabel)}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            if (!wide || !_mapMode)
                              _ViewToggle(
                                mapMode: _mapMode,
                                onChanged: (map) => setState(() => _mapMode = map),
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
                                ? _desktop(matches, ride)
                                : _mobile(matches, ride))
                            : matches.isEmpty
                                ? _empty()
                                : ListView.builder(
                                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                                    itemCount: matches.length,
                                    itemBuilder: (context, i) {
                                      final item = matches[i];
                                      final g = _gaps(item.request, ride);
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 10),
                                        child: NeedPostCard(
                                          need: item.request,
                                          onTap: () => _openAndRefresh('/ride/need/${item.request.id}'),
                                          footer: Column(
                                            crossAxisAlignment: CrossAxisAlignment.stretch,
                                            children: [
                                              Text(
                                                'Walk to pickup ${g.pickup} · Walk after drop ${g.drop}',
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                      fontWeight: FontWeight.w600,
                                                      color: AppTheme.ink,
                                                    ),
                                              ),
                                              const SizedBox(height: 8),
                                              SizedBox(
                                                height: 52,
                                                child: FilledButton(
                                                  onPressed: (_offering || item.alreadyOffered)
                                                      ? null
                                                      : () => _offer(item),
                                                  child: Text(item.alreadyOffered ? 'Offer sent' : 'Offer seat'),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
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

  Widget _empty() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      child: SoftPanel(
        child: EmptyState(
          title: 'No open requests nearby',
          subtitle: 'Share your ride — co-riders can still request a seat from Ride details',
          icon: Icons.hail_rounded,
          accent: AppTheme.brandOrange,
          actionLabel: 'Back to ride',
          onAction: () => context.go('/ride/detail/${widget.rideId}'),
        ),
      ),
    );
  }

  List<Polyline> _walkLines(RideRequest need) {
    final out = <Polyline>[];
    final pickup = _walkPickup[need.id];
    final drop = _walkDrop[need.id];
    if (pickup != null && pickup.points.length >= 2 && pickup.distanceMeters >= 12) {
      out.add(Polyline(
        points: pickup.points,
        color: AppTheme.brandBlue.withValues(alpha: 0.9),
        strokeWidth: 3.5,
        pattern: StrokePattern.dashed(segments: const [10, 8]),
      ));
    }
    if (drop != null && drop.points.length >= 2 && drop.distanceMeters >= 12) {
      out.add(Polyline(
        points: drop.points,
        color: AppTheme.brandOrange.withValues(alpha: 0.9),
        strokeWidth: 3.5,
        pattern: StrokePattern.dashed(segments: const [10, 8]),
      ));
    }
    return out;
  }

  Widget _map(List<NeedInboxItem> matches, Ride ride) {
    NeedInboxItem? selected;
    if (matches.isNotEmpty) {
      selected = matches[_pageIndex.clamp(0, matches.length - 1)];
    }
    final markers = <Marker>[
      OsmMapView.pin(LatLng(ride.originLat, ride.originLng)),
      OsmMapView.pin(LatLng(ride.destinationLat, ride.destinationLng), color: AppTheme.brandOrange),
    ];
    final selectedNeed = selected;
    if (selectedNeed != null) {
      final n = selectedNeed.request;
      markers.add(
        Marker(
          point: LatLng(n.originLat, n.originLng),
          width: 44,
          height: 44,
          child: const Icon(
            Icons.hail_rounded,
            color: AppTheme.brandOrange,
            size: 36,
          ),
        ),
      );
      markers.add(
        Marker(
          point: LatLng(n.destinationLat, n.destinationLng),
          width: 32,
          height: 32,
          child: const Icon(Icons.flag_rounded, color: AppTheme.brandOrange, size: 28),
        ),
      );
    }

    final hostPath = _hostRoute ??
        DriveRoute.fromJsonCoords(
          ride.routeGeometry,
          distanceMeters: ride.routeDistanceM,
          durationSeconds: ride.routeDurationS,
        );

    return SoftPanel(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            OsmMapView(
              center: LatLng(ride.originLat, ride.originLng),
              expand: true,
              fitToMarkers: true,
              markers: markers,
              routes: hostPath != null ? [hostPath] : const [],
              polylines: selected != null ? _walkLines(selected.request) : const [],
              selectedRouteIndex: 0,
            ),
            if (_loadingPaths)
              const Positioned(
                left: 10,
                top: 10,
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              ),
            if (selected?.request.poster != null)
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Material(
                  color: Colors.white.withValues(alpha: 0.96),
                  elevation: 2,
                  shadowColor: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                    child: PosterIdentity(
                      poster: selected!.request.poster!,
                      roleBadge: 'Co-rider',
                      dense: true,
                      maxInterests: 4,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _needCard(
    NeedInboxItem item,
    Ride ride, {
    required bool selected,
    required bool dense,
    VoidCallback? onSelect,
  }) {
    final n = item.request;
    final g = _gaps(n, ride);
    return Material(
      color: selected ? AppTheme.brandBlue.withValues(alpha: 0.04) : AppTheme.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: selected ? AppTheme.brandBlue : AppTheme.line, width: selected ? 2 : 1),
      ),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(16),
        mouseCursor: SystemMouseCursors.click,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.hail_rounded, color: selected ? AppTheme.brandOrange : AppTheme.brandBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (n.poster != null)
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  n.poster!.displayName,
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
                                  'Co-rider',
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
                          '${_short(n.originLabel, max: 34)} → ${_short(n.destinationLabel, max: 34)}',
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
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${DateFormat.MMMd().add_jm().format(n.departAt)} · '
                '${n.seatsNeeded} seat${n.seatsNeeded == 1 ? '' : 's'}'
                '${n.comfortPreferred ? ' · Comfort' : ''}'
                '${item.detourKm > 0 ? ' · ~${item.detourKm.toStringAsFixed(1)} km match' : ''}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Walk to pickup ${g.pickup} · Walk after drop ${g.drop}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.ink,
                    ),
              ),
              if (n.poster != null) ...[
                const SizedBox(height: 10),
                PosterIdentity(
                  poster: n.poster!,
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
                          onPressed: () => _openAndRefresh('/ride/need/${n.id}'),
                          child: const Text('Details'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: FilledButton(
                          onPressed: (_offering || item.alreadyOffered) ? null : () => _offer(item),
                          child: Text(item.alreadyOffered ? 'Offer sent' : 'Offer seat'),
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

  Widget _desktop(List<NeedInboxItem> matches, Ride ride) {
    NeedInboxItem? selected;
    if (matches.isNotEmpty) selected = matches[_pageIndex.clamp(0, matches.length - 1)];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 3, child: _map(matches, ride)),
          const SizedBox(width: 14),
          SizedBox(
            width: 400,
            child: SoftPanel(
              padding: EdgeInsets.zero,
              child: matches.isEmpty
                  ? Padding(padding: const EdgeInsets.all(16), child: _empty())
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text('Co-riders', style: Theme.of(context).textTheme.titleSmall),
                              ),
                              IconButton(
                                onPressed: _pageIndex > 0
                                    ? () => _selectNeed(matches, ride, _pageIndex - 1)
                                    : null,
                                icon: const Icon(Icons.chevron_left_rounded),
                              ),
                              IconButton(
                                onPressed: _pageIndex < matches.length - 1
                                    ? () => _selectNeed(matches, ride, _pageIndex + 1)
                                    : null,
                                icon: const Icon(Icons.chevron_right_rounded),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: matches.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, i) {
                              final item = matches[i];
                              return _needCard(
                                item,
                                ride,
                                selected: i == _pageIndex,
                                dense: true,
                                onSelect: () => _selectNeed(matches, ride, i),
                              );
                            },
                          ),
                        ),
                        if (selected != null) ...[
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                            child: Builder(
                              builder: (context) {
                                final item = selected!;
                                return Row(
                                  children: [
                                    Expanded(
                                      child: SizedBox(
                                        height: 52,
                                        child: OutlinedButton(
                                          onPressed: () =>
                                              _openAndRefresh('/ride/need/${item.request.id}'),
                                          child: const Text('Details'),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: SizedBox(
                                        height: 52,
                                        child: FilledButton(
                                          onPressed: (_offering || item.alreadyOffered)
                                              ? null
                                              : () => _offer(item),
                                          child: Text(
                                            item.alreadyOffered ? 'Offer sent' : 'Offer seat',
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
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

  Widget _mobile(List<NeedInboxItem> matches, Ride ride) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        children: [
          Expanded(child: _map(matches, ride)),
          const SizedBox(height: 10),
          if (matches.isEmpty)
            _empty()
          else
            SizedBox(
              height: 200,
              child: PageView.builder(
                controller: _pageController,
                itemCount: matches.length,
                onPageChanged: (i) => _selectNeed(matches, ride, i, animatePage: false),
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _needCard(
                    matches[i],
                    ride,
                    selected: i == _pageIndex,
                    dense: false,
                    onSelect: () => _selectNeed(matches, ride, i, animatePage: false),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Bundle {
  _Bundle({required this.ride, required this.matches});
  final Ride ride;
  final List<NeedInboxItem> matches;
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
          _ToggleBtn(icon: Icons.view_list_rounded, selected: !mapMode, onTap: () => onChanged(false)),
          _ToggleBtn(icon: Icons.map_rounded, selected: mapMode, onTap: () => onChanged(true)),
        ],
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  const _ToggleBtn({required this.icon, required this.selected, required this.onTap});

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        width: 36,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppTheme.brandBlue.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, size: 18, color: selected ? AppTheme.brandBlue : AppTheme.inkMuted),
      ),
    );
  }
}
