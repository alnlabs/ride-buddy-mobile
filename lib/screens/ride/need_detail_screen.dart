import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ridebuddy/models/models.dart';
import 'package:ridebuddy/providers/auth_provider.dart';
import 'package:ridebuddy/services/api_client.dart';
import 'package:ridebuddy/services/ride_repository.dart';
import 'package:ridebuddy/widgets/common/comfort_booking.dart';
import 'package:ridebuddy/widgets/common/empty_state.dart';
import 'package:ridebuddy/widgets/common/ui_kit.dart';
import 'package:ridebuddy/widgets/ride/need_post_card.dart';
import 'package:ridebuddy/widgets/ride/post_share_sheet.dart';
import 'package:ridebuddy/widgets/ride/ride_post_card.dart';

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

  Future<void> _share(RideRequest need) async {
    try {
      final payload = await ref.read(rideRepositoryProvider).shareNeed(need.id);
      final text = (payload['text'] as String?)?.trim() ?? '';
      final link = (payload['link'] as String?)?.trim() ?? '';
      if (!mounted || text.isEmpty) return;
      await showPostShareSheet(
        context,
        title: 'Share need',
        text: text,
        link: link,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ref.read(apiClientProvider).messageFrom(e))),
      );
    }
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

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(authStateProvider).userId;

    return FutureBuilder<_NeedBundle>(
      future: _future,
      builder: (context, snap) {
        final canShare = snap.hasData && snap.data!.need.status == 'open';
        return SkyScaffold(
          appBar: AppBar(
            title: const Text('Seat need'),
            actions: [
              if (canShare)
                IconButton(
                  tooltip: 'Share',
                  onPressed: () => _share(snap.data!.need),
                  icon: const Icon(Icons.ios_share_rounded),
                ),
            ],
          ),
          child: () {
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
            final isOwner = me == need.requesterId;
            final pendingOffers = bundle.offers.where((o) => o.status == 'offered').toList();

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [
                  NeedPostCard(
                    need: need,
                    isOwner: isOwner,
                    compact: false,
                    statusLabel: need.status,
                    footer: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (need.status == 'open')
                          OutlinedButton(
                            onPressed: _acting || !isOwner ? null : () => _cancel(need),
                            child: const Text('Cancel need'),
                          ),
                        if (need.matchedRideId != null) ...[
                          const SizedBox(height: 8),
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
                        if (ride != null) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: RidePostCard(
                              ride: ride,
                              footer: Row(
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
                            ),
                          );
                        }
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: SoftPanel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
                          child: RidePostCard(
                            ride: r,
                            onTap: () => context.push(
                              '/ride/detail/${r.id}${need.comfortPreferred ? '?preferComfort=1' : ''}',
                            ),
                            footer: Align(
                              alignment: Alignment.centerRight,
                              child: FilledButton.tonal(
                                onPressed: _acting ? null : () => _bookMatch(r, need),
                                child: const Text('Request seat'),
                              ),
                            ),
                          ),
                        );
                      }),
                  ],
                ],
              ),
            );
          }(),
        );
      },
    );
  }
}

class _NeedBundle {
  _NeedBundle({required this.need, required this.matches, required this.offers});
  final RideRequest need;
  final List<Ride> matches;
  final List<RideOffer> offers;
}
