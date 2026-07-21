import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ridebuddy/models/models.dart';
import 'package:ridebuddy/providers/auth_provider.dart';
import 'package:ridebuddy/providers/chat_provider.dart';
import 'package:ridebuddy/providers/ride_hub_focus_provider.dart';
import 'package:ridebuddy/screens/profile/profile_screen.dart';
import 'package:ridebuddy/services/api_client.dart';
import 'package:ridebuddy/services/chat_repository.dart';
import 'package:ridebuddy/services/ride_repository.dart';
import 'package:ridebuddy/widgets/common/comfort_booking.dart';
import 'package:ridebuddy/widgets/common/empty_state.dart';
import 'package:ridebuddy/widgets/common/ui_kit.dart';
import 'package:ridebuddy/widgets/ride/need_post_card.dart';
import 'package:ridebuddy/widgets/ride/post_share_sheet.dart';
import 'package:ridebuddy/widgets/ride/ride_post_card.dart';

class NeedDetailScreen extends ConsumerStatefulWidget {
  const NeedDetailScreen({
    super.key,
    required this.requestId,
    this.initialMatchesMap = false,
  });

  final String requestId;
  /// Kept for route compatibility; Find rides opens the available-rides map.
  final bool initialMatchesMap;

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
    final offers = await repo.needOffers(widget.requestId);
    return _NeedBundle(need: need, offers: offers);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  Future<void> _openAndRefresh(String location) async {
    await context.push(location);
    if (mounted) await _refresh();
  }

  Future<void> _share(RideRequest need) async {
    try {
      final payload = await ref.read(rideRepositoryProvider).shareNeed(need.id);
      final text = (payload['text'] as String?)?.trim() ?? '';
      final link = (payload['link'] as String?)?.trim() ?? '';
      if (!mounted || text.isEmpty) return;
      await showPostShareSheet(
        context,
        title: 'Share request',
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
        title: const Text('Cancel this request?'),
        content: const Text('Hosts won’t see it anymore.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Cancel request')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _acting = true);
    try {
      await ref.read(rideRepositoryProvider).cancelNeed(need.id);
      if (!mounted) return;
      bumpRideData(ref);
      ref.invalidate(seatRequestCountProvider);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request cancelled')));
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
      bumpRideData(ref);
      ref.invalidate(seatRequestCountProvider);
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

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(authStateProvider).userId;

    return FutureBuilder<_NeedBundle>(
      future: _future,
      builder: (context, snap) {
        final canShare = snap.hasData && snap.data!.need.status == 'open';
        final isOwnerTitle =
            snap.hasData && me == snap.data!.need.requesterId;
        return SkyScaffold(
          appBar: AppBar(
            title: Text(isOwnerTitle ? 'My request' : 'Seat request'),
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
                    title: 'Couldn’t load request',
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
                        if (need.status == 'open' && isOwner) ...[
                          PrimaryButton(
                            label: 'Find rides',
                            icon: Icons.map_rounded,
                            onPressed: () => _openAndRefresh('/ride/available/${need.id}'),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton(
                            onPressed: _acting ? null : () => _cancel(need),
                            child: const Text('Cancel request'),
                          ),
                        ],
                        if (need.matchedRideId != null) ...[
                          const SizedBox(height: 8),
                          PrimaryButton(
                            label: 'Open matched ride',
                            icon: Icons.directions_car_rounded,
                            onPressed: () => _openAndRefresh('/ride/detail/${need.matchedRideId}'),
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
                              footer: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  TextButton.icon(
                                    onPressed: _acting
                                        ? null
                                        : () async {
                                            final nav = GoRouter.of(context);
                                            final messenger = ScaffoldMessenger.of(context);
                                            try {
                                              final conv = await ref
                                                  .read(chatRepositoryProvider)
                                                  .open(offerId: o.id);
                                              ref.invalidate(chatInboxProvider);
                                              if (!mounted) return;
                                              nav.push('/chat/${conv.id}');
                                            } catch (e) {
                                              if (!mounted) return;
                                              messenger.showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    ref.read(apiClientProvider).messageFrom(e),
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                                    label: const Text('Message host'),
                                  ),
                                  const SizedBox(height: 8),
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
  _NeedBundle({required this.need, required this.offers});
  final RideRequest need;
  final List<RideOffer> offers;
}
