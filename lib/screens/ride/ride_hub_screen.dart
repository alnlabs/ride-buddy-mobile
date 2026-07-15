import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:ridebuddy/models/models.dart';
import 'package:ridebuddy/providers/location_provider.dart';
import 'package:ridebuddy/services/api_client.dart';
import 'package:ridebuddy/services/ride_repository.dart';
import 'package:ridebuddy/services/routing_service.dart';
import 'package:ridebuddy/theme/app_theme.dart';
import 'package:ridebuddy/widgets/common/empty_state.dart';
import 'package:ridebuddy/widgets/common/poster_identity.dart';
import 'package:ridebuddy/widgets/common/ui_kit.dart';
import 'package:ridebuddy/widgets/maps/osm_map_view.dart';

class RideHubScreen extends ConsumerStatefulWidget {
  const RideHubScreen({super.key});

  @override
  ConsumerState<RideHubScreen> createState() => _RideHubScreenState();
}

class _RideHubScreenState extends ConsumerState<RideHubScreen> {
  late Future<_HubData> _data;
  bool _mapMode = false;
  String? _selectedRideId;

  @override
  void initState() {
    super.initState();
    _data = _load();
  }

  Future<_HubData> _load() async {
    final repo = ref.read(rideRepositoryProvider);
    final open = await repo.openOwned();
    List<NeedInboxItem> inbox = const [];
    List<RideRequest> needs = const [];
    try {
      inbox = await repo.needsInbox();
    } catch (_) {}
    try {
      needs = await repo.myNeeds();
    } catch (_) {}
    return _HubData(openRides: open, inbox: inbox, myNeeds: needs);
  }

  Future<void> _refresh() async {
    setState(() => _data = _load());
    await _data;
  }

  void _openGetSeatSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppTheme.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Get a seat', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                'Search what’s already posted, or ask hosts to offer you one.',
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ActionRow(
                icon: Icons.search_rounded,
                title: 'Search rides',
                subtitle: 'Browse open seats on your route',
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/ride/search');
                },
              ),
              const SizedBox(height: 10),
              ActionRow(
                icon: Icons.hail_rounded,
                title: 'Post a need',
                subtitle: 'Hosts nearby can offer you a seat',
                accent: AppTheme.brandOrange,
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/ride/needs/new');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _short(String label, {int max = 28}) {
    if (label.length <= max) return label;
    return '${label.substring(0, max - 2)}…';
  }

  @override
  Widget build(BuildContext context) {
    final regionAsync = ref.watch(officeMapRegionProvider);

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
              final inboxCount = data?.inbox.length ?? 0;
              final openNeeds = data?.myNeeds.where((n) => n.status == 'open').length ?? 0;

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
                            'Office carpool · share the trip cost',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.inkMuted),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: _PrimaryTile(
                                  title: 'Get a seat',
                                  subtitle: 'As co-rider',
                                  icon: Icons.airline_seat_recline_normal_rounded,
                                  color: AppTheme.brandBlue,
                                  onTap: _openGetSeatSheet,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _PrimaryTile(
                                  title: 'Offer seats',
                                  subtitle: 'As host',
                                  icon: Icons.directions_car_filled_rounded,
                                  color: AppTheme.brandOrange,
                                  onTap: () => context.push('/ride/post'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _LinkChip(
                                  icon: Icons.confirmation_number_outlined,
                                  label: 'My trips',
                                  onTap: () => context.push('/ride/trips'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _LinkChip(
                                  icon: Icons.inbox_outlined,
                                  label: inboxCount > 0 ? 'Needs · $inboxCount' : 'Needs',
                                  onTap: () => context.push('/ride/needs'),
                                ),
                              ),
                              if (openNeeds > 0) ...[
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _LinkChip(
                                    icon: Icons.hail_rounded,
                                    label: 'Mine · $openNeeds',
                                    onTap: () => context.push('/ride/needs'),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 22),
                          Row(
                            children: [
                              const Expanded(child: SectionLabel('Your open rides')),
                              _ViewToggle(
                                mapMode: _mapMode,
                                onChanged: (map) => setState(() {
                                  _mapMode = map;
                                  if (!map) _selectedRideId = null;
                                }),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                  if (loading)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverToBoxAdapter(
                        child: SoftPanel(child: const LinearProgressIndicator()),
                      ),
                    )
                  else if (snap.hasError)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
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
                  else if (open.isEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverToBoxAdapter(
                        child: SoftPanel(
                          child: EmptyState(
                            title: 'No open rides yet',
                            subtitle: 'Offer seats from your vehicle to see them here and on the map',
                            actionLabel: 'Offer seats',
                            onAction: () => context.push('/ride/post'),
                          ),
                        ),
                      ),
                    )
                  else if (_mapMode)
                    _buildMapSliver(open, regionAsync)
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) {
                            final r = open[i];
                            final when = DateFormat.MMMd().add_jm().format(r.departAt);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: SoftPanel(
                                onTap: () => context.push('/ride/detail/${r.id}'),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: AppTheme.brandOrange.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.route_rounded, color: AppTheme.brandOrange),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (r.poster != null) ...[
                                            PosterIdentity(poster: r.poster!, roleBadge: 'Host', dense: true),
                                            const SizedBox(height: 8),
                                          ],
                                          Text(
                                            '${_short(r.originLabel)} → ${_short(r.destinationLabel)}',
                                            style: Theme.of(context).textTheme.titleMedium,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '$when · ${r.availableSeats} seats'
                                            '${r.comfortRide ? ' · Comfort' : ''}',
                                            style: Theme.of(context).textTheme.bodySmall,
                                          ),
                                          const SizedBox(height: 6),
                                          FareChip(pricePerSeat: r.pricePerSeat, compact: true),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right_rounded, color: AppTheme.inkMuted),
                                  ],
                                ),
                              ),
                            );
                          },
                          childCount: open.length,
                        ),
                      ),
                    ),
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
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: OsmMapView(
                      center: center,
                      expand: true,
                      fitToMarkers: true,
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
                        child: InkWell(
                          onTap: () => context.push('/ride/detail/${ride.id}'),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
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
    required this.inbox,
    required this.myNeeds,
  });

  final List<Ride> openRides;
  final List<NeedInboxItem> inbox;
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
      color: color,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.white, size: 26),
              const SizedBox(height: 18),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LinkChip extends StatelessWidget {
  const _LinkChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceElevated,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.line),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: AppTheme.brandBlue),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
