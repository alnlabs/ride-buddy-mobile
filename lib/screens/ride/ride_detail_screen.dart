import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:ridebuddy/models/models.dart';
import 'package:ridebuddy/models/trip_guidelines.dart';
import 'package:ridebuddy/providers/auth_provider.dart';
import 'package:ridebuddy/services/api_client.dart';
import 'package:ridebuddy/services/nominatim_service.dart';
import 'package:ridebuddy/services/ride_repository.dart';
import 'package:ridebuddy/services/routing_service.dart';
import 'package:ridebuddy/services/whatsapp_share.dart';
import 'package:ridebuddy/theme/app_theme.dart';
import 'package:ridebuddy/widgets/common/comfort_booking.dart';
import 'package:ridebuddy/widgets/common/error_view.dart';
import 'package:ridebuddy/widgets/common/loading_skeleton.dart';
import 'package:ridebuddy/widgets/common/poster_identity.dart';
import 'package:ridebuddy/widgets/common/ui_kit.dart';
import 'package:ridebuddy/widgets/maps/osm_map_view.dart';
import 'package:ridebuddy/widgets/maps/place_search_field.dart';
import 'package:ridebuddy/widgets/trip/trip_guidelines_sheet.dart';
import 'package:share_plus/share_plus.dart';

class RideDetailScreen extends ConsumerStatefulWidget {
  const RideDetailScreen({
    super.key,
    required this.rideId,
    this.preferComfort = false,
  });

  final String rideId;
  final bool preferComfort;

  @override
  ConsumerState<RideDetailScreen> createState() => _RideDetailScreenState();
}

class _RideDetailScreenState extends ConsumerState<RideDetailScreen> {
  Ride? _ride;
  String? _error;
  bool _loading = true;
  DriveRoute? _displayRoute;
  bool _routing = false;
  TripGuidelines? _guidelines;
  Booking? _myBooking;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _displayRoute = null;
    });
    try {
      final repo = ref.read(rideRepositoryProvider);
      final ride = await repo.getRide(widget.rideId);
      final trips = await repo.myBookings();
      Booking? mine;
      for (final b in trips) {
        if (b.rideId == widget.rideId && b.status != 'cancelled' && b.status != 'rejected') {
          mine = b;
          break;
        }
      }
      TripGuidelines? guidelines;
      try {
        if (mine != null && (mine.status == 'accepted' || mine.status == 'requested')) {
          guidelines = await repo.tripGuidelinesForBooking(mine.id);
        } else {
          guidelines = await repo.tripGuidelinesForRide(widget.rideId);
        }
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _ride = ride;
        _myBooking = mine;
        _guidelines = guidelines;
      });
      await _ensureRoute(ride);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = ref.read(apiClientProvider).messageFrom(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _ensureRoute(Ride ride) async {
    final saved = DriveRoute.fromJsonCoords(
      ride.routeGeometry,
      distanceMeters: ride.routeDistanceM,
      durationSeconds: ride.routeDurationS,
    );
    if (saved != null && saved.points.length >= 2) {
      setState(() => _displayRoute = saved);
      return;
    }
    // Older rides (or failed save) — resolve a live driving path for display.
    setState(() => _routing = true);
    try {
      final list = await ref.read(routingServiceProvider).routes(
            LatLng(ride.originLat, ride.originLng),
            LatLng(ride.destinationLat, ride.destinationLng),
          );
      if (!mounted) return;
      setState(() => _displayRoute = list.isNotEmpty ? list.first : null);
    } catch (_) {
      if (!mounted) return;
      setState(() => _displayRoute = null);
    } finally {
      if (mounted) setState(() => _routing = false);
    }
  }

  Future<void> _share() async {
    try {
      final payload = await ref.read(rideRepositoryProvider).share(widget.rideId);
      final text = (payload['text'] as String?)?.trim() ?? '';
      final link = (payload['link'] as String?)?.trim() ?? '';
      if (!mounted || text.isEmpty) return;

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: AppTheme.surfaceElevated,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.line,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Share ride', style: Theme.of(ctx).textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  'Preview of the WhatsApp message',
                  style: Theme.of(ctx).textTheme.bodyMedium,
                ),
                const SizedBox(height: 14),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(ctx).size.height * 0.42,
                  ),
                  child: SoftPanel(
                    padding: const EdgeInsets.all(14),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        text,
                        style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.ink,
                              height: 1.45,
                            ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Share on WhatsApp',
                  icon: Icons.chat_rounded,
                  backgroundColor: const Color(0xFF25D366),
                  onPressed: () async {
                    await shareTextToWhatsApp(text);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: text));
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(content: Text('Message copied')),
                            );
                          }
                        },
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        label: const Text('Copy text'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: link.isEmpty
                            ? null
                            : () async {
                                await Clipboard.setData(ClipboardData(text: link));
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(content: Text('Link copied')),
                                  );
                                }
                              },
                        icon: const Icon(Icons.link_rounded, size: 18),
                        label: const Text('Copy link'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () async {
                    await SharePlus.instance.share(ShareParams(text: text));
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('More apps…'),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ref.read(apiClientProvider).messageFrom(e))),
      );
    }
  }

  Future<void> _book() async {
    final ride = _ride!;
    final proceed = await confirmCompactBookingIfNeeded(
      context,
      preferComfort: widget.preferComfort,
      rideIsComfort: ride.comfortRide,
    );
    if (!proceed || !mounted) return;

    PlaceSuggestion? pickup = PlaceSuggestion(label: ride.originLabel, lat: ride.originLat, lng: ride.originLng);
    PlaceSuggestion? drop = PlaceSuggestion(label: ride.destinationLabel, lat: ride.destinationLat, lng: ride.destinationLng);
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            final ridePath = _displayRoute ??
                DriveRoute.fromJsonCoords(
                  ride.routeGeometry,
                  distanceMeters: ride.routeDistanceM,
                  durationSeconds: ride.routeDurationS,
                );
            return Padding(
              padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Request this seat', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(
                    'This is a carpool, not a taxi. Pay the shared seat amount in cash to the host when you meet.',
                    style: Theme.of(ctx).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  FareChip(pricePerSeat: ride.pricePerSeat),
                  if (_guidelines != null) ...[
                    const SizedBox(height: 12),
                    TripGuidelinesBanner(guidelines: _guidelines!, compact: true),
                  ],
                  const SizedBox(height: 12),
                  PlaceSearchField(
                    label: 'Pickup',
                    initialText: pickup?.label,
                    onSelected: (p) => setModal(() => pickup = p),
                  ),
                  const SizedBox(height: 8),
                  PlaceSearchField(
                    label: 'Drop',
                    initialText: drop?.label,
                    onSelected: (p) => setModal(() => drop = p),
                  ),
                  const SizedBox(height: 8),
                  OsmMapView(
                    height: 160,
                    center: LatLng(pickup!.lat, pickup!.lng),
                    markers: [
                      OsmMapView.pin(LatLng(pickup!.lat, pickup!.lng)),
                      OsmMapView.pin(LatLng(drop!.lat, drop!.lng), color: AppTheme.brandOrange),
                    ],
                    routes: ridePath != null ? [ridePath] : const [],
                    polylines: ridePath != null
                        ? const []
                        : [
                            Polyline(
                              points: [LatLng(pickup!.lat, pickup!.lng), LatLng(drop!.lat, drop!.lng)],
                              color: AppTheme.brandBlue,
                              strokeWidth: 3,
                            ),
                          ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Request seat'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (ok != true || pickup == null || drop == null) return;
    await ref.read(rideRepositoryProvider).book({
      'rideId': ride.id,
      'seatsRequested': 1,
      'pickupLat': pickup!.lat,
      'pickupLng': pickup!.lng,
      'pickupLabel': pickup!.label,
      'dropLat': drop!.lat,
      'dropLng': drop!.lng,
      'dropLabel': drop!.label,
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking requested')));
      context.push('/ride/trips');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: LoadingSkeleton(count: 3));
    if (_error != null || _ride == null) {
      return Scaffold(body: ErrorView(message: _error ?? 'Not found', onRetry: _load));
    }
    final r = _ride!;
    final me = ref.watch(authStateProvider).userId;
    final isHost = me == r.ownerId;
    final origin = LatLng(r.originLat, r.originLng);
    final dest = LatLng(r.destinationLat, r.destinationLng);
    final path = _displayRoute;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride details'),
        actions: [
          IconButton(onPressed: _share, icon: const Icon(Icons.share)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (r.poster != null) ...[
            SoftPanel(
              child: PosterIdentity(poster: r.poster!, roleBadge: 'Host'),
            ),
            const SizedBox(height: 12),
          ],
          Text('${r.originLabel} → ${r.destinationLabel}', style: Theme.of(context).textTheme.titleMedium),
          Text(DateFormat.yMMMd().add_jm().format(r.departAt)),
          Text('${r.availableSeats} seats available'
              '${r.comfortRide ? ' · Comfort (2 in back)' : ' · Standard'}'),
          if (r.commuteMatchType != null) Text('Match: ${r.commuteMatchType}'),
          if (path != null && path.distanceMeters > 0)
            Text('Path · ${path.distanceLabel} · ${path.durationLabel}'),
          const SizedBox(height: 12),
          FareChip(pricePerSeat: r.pricePerSeat, emphasize: true),
          if (_guidelines != null) ...[
            const SizedBox(height: 12),
            TripGuidelinesBanner(guidelines: _guidelines!),
          ],
          const SizedBox(height: 12),
          OsmMapView(
            center: origin,
            height: 240,
            fitToMarkers: true,
            markers: [
              OsmMapView.pin(origin),
              OsmMapView.pin(dest, color: AppTheme.brandOrange),
            ],
            routes: path != null ? [path] : const [],
            polylines: path != null
                ? const []
                : [
                    Polyline(points: [origin, dest], color: AppTheme.brandBlue, strokeWidth: 4),
                  ],
          ),
          if (_routing)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: LinearProgressIndicator(),
            ),
          const SizedBox(height: 8),
          Text('Map © OpenStreetMap', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          const SizedBox(height: 16),
          if (!isHost)
            ElevatedButton(
              onPressed: r.status == 'open' && (_myBooking == null) ? _book : null,
              child: Text(_myBooking != null ? 'Seat ${_myBooking!.status}' : 'Request seat'),
            ),
          if (isHost) ...[
            OutlinedButton(
              onPressed: () async {
                final nav = Navigator.of(context);
                await ref.read(rideRepositoryProvider).cancelRide(r.id);
                nav.pop();
              },
              child: const Text('Cancel ride'),
            ),
            const SizedBox(height: 12),
            const Text('Booking requests', style: TextStyle(fontWeight: FontWeight.bold)),
            FutureBuilder(
              future: ref.read(rideRepositoryProvider).bookingsForRide(r.id),
              builder: (context, snap) {
                if (!snap.hasData) return const LinearProgressIndicator();
                final list = snap.data!;
                if (list.isEmpty) return const Text('No requests yet');
                return Column(
                  children: list.map((b) {
                    return ListTile(
                      title: Text('${b.status} · ${b.seatsRequested} seat(s)'),
                      subtitle: Text('${b.pickupLabel} → ${b.dropLabel}'),
                      trailing: b.status == 'requested'
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.check, color: Colors.green),
                                  onPressed: () async {
                                    await ref.read(rideRepositoryProvider).decideBooking(b.id, true);
                                    _load();
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.red),
                                  onPressed: () async {
                                    await ref.read(rideRepositoryProvider).decideBooking(b.id, false);
                                    _load();
                                  },
                                ),
                              ],
                            )
                          : null,
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
