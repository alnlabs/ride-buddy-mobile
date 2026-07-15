import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ridebuddy/models/models.dart';
import 'package:ridebuddy/services/api_client.dart';
import 'package:ridebuddy/services/ride_repository.dart';
import 'package:ridebuddy/theme/app_theme.dart';
import 'package:ridebuddy/widgets/common/comfort_booking.dart';
import 'package:ridebuddy/widgets/common/empty_state.dart';
import 'package:ridebuddy/widgets/common/poster_identity.dart';
import 'package:ridebuddy/widgets/common/ui_kit.dart';

class NeedDetailScreen extends ConsumerStatefulWidget {
  const NeedDetailScreen({super.key, required this.requestId});

  final String requestId;

  @override
  ConsumerState<NeedDetailScreen> createState() => _NeedDetailScreenState();
}

class _NeedDetailScreenState extends ConsumerState<NeedDetailScreen> {
  late Future<_NeedBundle> _future;
  bool _acting = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_NeedBundle> _load() async {
    final repo = ref.read(rideRepositoryProvider);
    final need = await repo.getNeed(widget.requestId);
    final matches = need.status == 'open' ? await repo.needMatches(widget.requestId) : <Ride>[];
    final offers = await repo.needOffers(widget.requestId);
    return _NeedBundle(need: need, matches: matches, offers: offers);
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _cancel(RideRequest need) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel this need?'),
        content: const Text('Hosts won’t see it anymore.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Cancel need')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _acting = true);
    try {
      await ref.read(rideRepositoryProvider).cancelNeed(need.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Need cancelled')));
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ref.read(apiClientProvider).messageFrom(e))),
      );
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _decideOffer(RideOffer offer, bool accept) async {
    if (accept) {
      final need = await ref.read(rideRepositoryProvider).getNeed(widget.requestId);
      if (!mounted) return;
      final proceed = await confirmCompactBookingIfNeeded(
        context,
        preferComfort: need.comfortPreferred,
        rideIsComfort: offer.ride?.comfortRide ?? false,
      );
      if (!proceed || !mounted) return;
    }
    setState(() => _acting = true);
    try {
      await ref.read(rideRepositoryProvider).decideOffer(offer.id, accept);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(accept ? 'Seat accepted — you’re booked' : 'Offer declined')),
      );
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ref.read(apiClientProvider).messageFrom(e))),
      );
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _bookMatch(Ride ride, RideRequest need) async {
    final proceed = await confirmCompactBookingIfNeeded(
      context,
      preferComfort: need.comfortPreferred,
      rideIsComfort: ride.comfortRide,
    );
    if (!proceed || !mounted) return;

    setState(() => _acting = true);
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking requested — waiting for host')),
      );
      context.push('/ride/detail/${ride.id}${need.comfortPreferred ? '?preferComfort=1' : ''}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ref.read(apiClientProvider).messageFrom(e))),
      );
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  String _short(String label) {
    if (label.length <= 36) return label;
    return '${label.substring(0, 34)}…';
  }

  @override
  Widget build(BuildContext context) {
    return SkyScaffold(
      appBar: AppBar(title: const Text('Your need')),
      child: FutureBuilder<_NeedBundle>(
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
                  title: 'Couldn’t load need',
                  subtitle: ref.read(apiClientProvider).messageFrom(snap.error!),
                  actionLabel: 'Retry',
                  onAction: _refresh,
                ),
              ),
            );
          }
          final bundle = snap.data!;
          final need = bundle.need;
          final pendingOffers = bundle.offers.where((o) => o.status == 'offered').toList();

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                SoftPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (need.poster != null) ...[
                        PosterIdentity(poster: need.poster!, roleBadge: 'Needs seat'),
                        const SizedBox(height: 12),
                      ],
                      Text(
                        '${_short(need.originLabel)} → ${_short(need.destinationLabel)}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${DateFormat.MMMd().add_jm().format(need.departAt)} · '
                        '${need.seatsNeeded} seat${need.seatsNeeded == 1 ? '' : 's'}'
                        '${need.comfortPreferred ? ' · Comfort' : ''}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 10),
                      _StatusPill(need.status),
                      if (need.status == 'open') ...[
                        const SizedBox(height: 14),
                        OutlinedButton(
                          onPressed: _acting ? null : () => _cancel(need),
                          child: const Text('Cancel need'),
                        ),
                      ],
                      if (need.matchedRideId != null) ...[
                        const SizedBox(height: 12),
                        PrimaryButton(
                          label: 'Open matched ride',
                          icon: Icons.directions_car_rounded,
                          onPressed: () => context.push('/ride/detail/${need.matchedRideId}'),
                        ),
                      ],
                    ],
                  ),
                ),
                if (need.status == 'open') ...[
                  const SizedBox(height: 22),
                  const SectionLabel('Offers from hosts'),
                  const SizedBox(height: 10),
                  if (pendingOffers.isEmpty)
                    const SoftPanel(
                      child: EmptyState(
                        title: 'No offers yet',
                        subtitle: 'Hosts with matching rides can offer you a seat',
                        icon: Icons.mail_outline_rounded,
                      ),
                    )
                  else
                    ...pendingOffers.map((o) {
                      final ride = o.ride;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: SoftPanel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (ride?.poster != null) ...[
                                PosterIdentity(poster: ride!.poster!, roleBadge: 'Host', dense: true),
                                const SizedBox(height: 10),
                              ],
                              if (ride != null) ...[
                                Text(
                                  '${_short(ride.originLabel)} → ${_short(ride.destinationLabel)}',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${DateFormat.MMMd().add_jm().format(ride.departAt)} · '
                                  '₹${ride.pricePerSeat.toStringAsFixed(0)} / seat',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 8),
                                FareChip(pricePerSeat: ride.pricePerSeat, compact: true),
                              ] else
                                Text('Ride ${o.rideId}', style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: _acting ? null : () => _decideOffer(o, false),
                                      child: const Text('Decline'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: FilledButton(
                                      onPressed: _acting ? null : () => _decideOffer(o, true),
                                      child: const Text('Accept'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 22),
                  const SectionLabel('Matching rides — book yourself'),
                  const SizedBox(height: 10),
                  if (bundle.matches.isEmpty)
                    const SoftPanel(
                      child: EmptyState(
                        title: 'No matching rides',
                        subtitle: 'Try posting earlier or widen your route',
                        icon: Icons.search_off_rounded,
                      ),
                    )
                  else
                    ...bundle.matches.map((r) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child:                         SoftPanel(
                          onTap: () => context.push(
                            '/ride/detail/${r.id}${need.comfortPreferred ? '?preferComfort=1' : ''}',
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (r.poster != null) ...[
                                PosterIdentity(poster: r.poster!, roleBadge: 'Host', dense: true),
                                const SizedBox(height: 10),
                              ],
                              Text(
                                '${_short(r.originLabel)} → ${_short(r.destinationLabel)}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${DateFormat.MMMd().add_jm().format(r.departAt)} · '
                                '${r.availableSeats} seats'
                                '${r.comfortRide ? ' · Comfort' : (need.comfortPreferred ? ' · Compact' : '')}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 8),
                              FareChip(pricePerSeat: r.pricePerSeat, compact: true),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: FilledButton.tonal(
                                  onPressed: _acting ? null : () => _bookMatch(r, need),
                                  child: const Text('Request seat'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _NeedBundle {
  _NeedBundle({required this.need, required this.matches, required this.offers});
  final RideRequest need;
  final List<Ride> matches;
  final List<RideOffer> offers;
}

class _StatusPill extends StatelessWidget {
  const _StatusPill(this.status);
  final String status;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      'open' => 'Open',
      'matched' => 'Matched',
      'cancelled' => 'Cancelled',
      'expired' => 'Expired',
      _ => status,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.brandBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(color: AppTheme.brandBlue, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}
