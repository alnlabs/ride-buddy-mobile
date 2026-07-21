import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:ridebuddy/models/models.dart';
import 'package:ridebuddy/providers/auth_provider.dart';
import 'package:ridebuddy/providers/location_provider.dart';
import 'package:ridebuddy/providers/ride_hub_focus_provider.dart';
import 'package:ridebuddy/services/api_client.dart';
import 'package:ridebuddy/services/place_label_formatter.dart';
import 'package:ridebuddy/services/ride_repository.dart';
import 'package:ridebuddy/services/routing_service.dart';
import 'package:ridebuddy/theme/app_theme.dart';
import 'package:ridebuddy/widgets/common/empty_state.dart';
import 'package:ridebuddy/widgets/common/ui_kit.dart';
import 'package:ridebuddy/widgets/maps/osm_map_view.dart';
import 'package:ridebuddy/widgets/ride/need_post_card.dart';
import 'package:ridebuddy/widgets/ride/ride_post_card.dart';

class RideHubScreen extends ConsumerStatefulWidget {
  const RideHubScreen({super.key});

  @override
  ConsumerState<RideHubScreen> createState() => _RideHubScreenState();
}

class _RideHubScreenState extends ConsumerState<RideHubScreen> {
  late Future<_HubData> _data;
  bool _mapMode = false;
  String? _selectedRideId;
  String? _loadedForUserId;

  @override
  void initState() {
    super.initState();
    _loadedForUserId = ref.read(authStateProvider).userId;
    _data = _load();
  }

  Future<_HubData> _load() async {
    final repo = ref.read(rideRepositoryProvider);
    final open = await repo.openOwned();
    List<RideRequest> needs = const [];
    try {
      needs = await repo.myNeeds();
    } catch (_) {}
    return _HubData(openRides: open, myNeeds: needs);
  }

  Future<void> _refresh() async {
    _loadedForUserId = ref.read(authStateProvider).userId;
    setState(() => _data = _load());
    await _data;
  }

  Future<void> _openAndRefresh(String location) async {
    await context.push(location);
    if (mounted) await _refresh();
  }

  String _short(String label, {int max = 28}) => PlaceLabelFormatter.shortenStoredLabel(label);

  @override
  Widget build(BuildContext context) {
    final regionAsync = ref.watch(officeMapRegionProvider);

    ref.listen<String?>(authStateProvider.select((s) => s.userId), (prev, next) {
      if (prev == next || next == _loadedForUserId) return;
      setState(() {
        _loadedForUserId = next;
        _selectedRideId = null;
        _mapMode = false;
        _data = _load();
      });
    });

    ref.listen<RideHubFocus?>(rideHubFocusProvider, (prev, next) {
      if (next == null) return;
      _refresh();
    });

    ref.listen<int>(rideDataRevisionProvider, (prev, next) {
      if (prev == next) return;
      _refresh();
    });

    return SkyScaffold(
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: FutureBuilder<_HubData>(
            future: _data,
            builder: (context, snap) {
              final data = snap.data;
              final loading = snap.connectionState != ConnectionState.done;
              final open = data?.openRides ?? const <Ride>[];
              final now = DateTime.now();
              final myAsks = (data?.myNeeds ?? const <RideRequest>[])
                  .where((n) =>
                      (n.status == 'open' || n.status == 'matched') &&
                      n.departAt.isAfter(now))
                  .toList();

              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Ride', style: Theme.of(context).textTheme.headlineMedium),
                          const SizedBox(height: 4),
                          Text(
                            'Share office trips · split the cost',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.inkMuted),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: _PrimaryTile(
                                  title: 'I need a ride',
                                  subtitle: 'Post request · see matches',
                                  icon: Icons.airline_seat_recline_normal_rounded,
                                  color: AppTheme.brandBlue,
                                  onTap: () => _openAndRefresh('/ride/search'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _PrimaryTile(
                                  title: "I'm offering",
                                  subtitle: 'Share empty seats',
                                  icon: Icons.directions_car_filled_rounded,
                                  color: AppTheme.brandOrange,
                                  onTap: () => _openAndRefresh('/ride/post'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (loading)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      sliver: SliverToBoxAdapter(
                        child: SoftPanel(child: const LinearProgressIndicator()),
                      ),
                    )
                  else if (snap.hasError)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      sliver: SliverToBoxAdapter(
                        child: SoftPanel(
                          child: EmptyState(
                            title: 'Couldn’t load rides',
                            subtitle: ref.read(apiClientProvider).messageFrom(snap.error!),
                            actionLabel: 'Retry',
                            onAction: _refresh,
                          ),
                        ),
                      ),
                    )
                  else ...[
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                      sliver: SliverToBoxAdapter(
                        child: SectionLabel(
                          myAsks.isEmpty ? 'My requests' : 'My requests · ${myAsks.length}',
                        ),
                      ),
                    ),
                    if (myAsks.isEmpty)
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                        sliver: SliverToBoxAdapter(
                          child: SoftPanel(
                            child: EmptyState(
                              title: 'No open requests',
                              subtitle: 'Use “I need a ride” above to post and find matches',
                              accent: AppTheme.brandBlue,
                              icon: Icons.hail_rounded,
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, i) {
                              final n = myAsks[i];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: NeedPostCard(
                                  need: n,
                                  isOwner: true,
                                  showPoster: false,
                                  showChevron: true,
                                  statusLabel: n.status,
                                  onTap: () => _openAndRefresh('/ride/need/${n.id}'),
                                ),
                              );
                            },
                            childCount: myAsks.length,
                          ),
                        ),
                      ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                      sliver: SliverToBoxAdapter(
                        child: Row(
                          children: [
                            Expanded(
                              child: SectionLabel(
                                open.isEmpty
                                    ? "Rides you're offering"
                                    : "Rides you're offering · ${open.length}",
                              ),
                            ),
                            TextButton(
                              onPressed: () => _openAndRefresh('/ride/needs'),
                              child: const Text('All requests'),
                            ),
                            if (open.isNotEmpty)
                              _ViewToggle(
                                mapMode: _mapMode,
                                onChanged: (map) => setState(() {
                                  _mapMode = map;
                                  if (!map) _selectedRideId = null;
                                }),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (open.isEmpty)
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
                        sliver: SliverToBoxAdapter(
                          child: SoftPanel(
                            child: EmptyState(
                              title: 'No rides offered yet',
                              subtitle: 'Use “I’m offering” above to post empty seats',
                              accent: AppTheme.brandOrange,
                              icon: Icons.directions_car_filled_rounded,
                            ),
                          ),
                        ),
                      )
                    else if (_mapMode)
                      _buildMapSliver(open, regionAsync)
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, i) {
                              final r = open[i];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: RidePostCard(
                                  ride: r,
                                  isOwner: true,
                                  showChevron: true,
                                  onTap: () => _openAndRefresh('/ride/detail/${r.id}'),
                                  footer: Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: () => _openAndRefresh('/ride/co-riders/${r.id}'),
                                      icon: const Icon(Icons.hail_rounded, size: 18),
                                      label: const Text('Find co-riders'),
                                    ),
                                  ),
                                ),
                              );
                            },
                            childCount: open.length,
                          ),
                        ),
                      ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMapSliver(List<Ride> open, AsyncValue<OfficeMapRegion> regionAsync) {
    Ride? selected;
    if (open.isNotEmpty) {
      selected = open.cast<Ride?>().firstWhere(
            (r) => r?.id == _selectedRideId,
            orElse: () => open.first,
          );
    }
    final center = selected != null
        ? LatLng(selected.originLat, selected.originLng)
        : regionAsync.maybeWhen(
            data: (r) => r.center,
            orElse: () => const LatLng(17.385, 78.4867),
          );

    final markers = <Marker>[];
    final routes = <DriveRoute>[];
    for (final r in open) {
      final isSelected = selected?.id == r.id;
      markers.add(
        Marker(
          point: LatLng(r.originLat, r.originLng),
          width: isSelected ? 48 : 40,
          height: isSelected ? 48 : 40,
          child: GestureDetector(
            onTap: () => setState(() => _selectedRideId = r.id),
            child: Icon(
              Icons.directions_car_filled_rounded,
              color: isSelected ? AppTheme.brandOrange : AppTheme.brandBlue,
              size: isSelected ? 36 : 30,
            ),
          ),
        ),
      );
      markers.add(
        OsmMapView.pin(
          LatLng(r.destinationLat, r.destinationLng),
          color: isSelected ? AppTheme.brandOrange : AppTheme.inkMuted,
        ),
      );
      final path = DriveRoute.fromJsonCoords(
        r.routeGeometry,
        distanceMeters: r.routeDistanceM,
        durationSeconds: r.routeDurationS,
      );
      if (path != null && isSelected) {
        routes.add(path);
      }
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 28),
      sliver: SliverToBoxAdapter(
        child: SoftPanel(
          padding: EdgeInsets.zero,
          child: SizedBox(
            height: 420,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: OsmMapView(
                      center: center,
                      expand: true,
                      fitToMarkers: true,
                      fitPadding: const EdgeInsets.all(28),
                      markers: markers,
                      routes: routes,
                      selectedRouteIndex: 0,
                    ),
                  ),
                ),
                if (selected != null) ...[
                  Builder(
                    builder: (context) {
                      final ride = selected!;
                      return Material(
                        color: AppTheme.surfaceElevated,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              InkWell(
                                onTap: () => _openAndRefresh('/ride/detail/${ride.id}'),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${_short(ride.originLabel, max: 34)} → ${_short(ride.destinationLabel, max: 34)}',
                                            style: Theme.of(context).textTheme.titleSmall,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${DateFormat.MMMd().add_jm().format(ride.departAt)} · '
                                            '${ride.availableSeats} seats',
                                            style: Theme.of(context).textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                    FareChip(pricePerSeat: ride.pricePerSeat, compact: true),
                                    const SizedBox(width: 6),
                                    const Icon(Icons.chevron_right_rounded, color: AppTheme.inkMuted),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              FilledButton.tonal(
                                onPressed: () => _openAndRefresh('/ride/co-riders/${ride.id}'),
                                child: const Text('Find co-riders'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HubData {
  const _HubData({
    required this.openRides,
    required this.myNeeds,
  });

  final List<Ride> openRides;
  final List<RideRequest> myNeeds;
}

class _PrimaryTile extends StatelessWidget {
  const _PrimaryTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceElevated,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.ink,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.inkMuted,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
      child: Container(
        width: 36,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppTheme.brandBlue.withOpacity(0.12) : Colors.transparent,
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
