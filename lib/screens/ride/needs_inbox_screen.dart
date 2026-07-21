import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ridebuddy/models/models.dart';
import 'package:ridebuddy/providers/auth_provider.dart';
import 'package:ridebuddy/providers/ride_hub_focus_provider.dart';
import 'package:ridebuddy/screens/profile/profile_screen.dart';
import 'package:ridebuddy/services/api_client.dart';
import 'package:ridebuddy/services/ride_repository.dart';
import 'package:ridebuddy/theme/app_theme.dart';
import 'package:ridebuddy/widgets/common/empty_state.dart';
import 'package:ridebuddy/widgets/common/ui_kit.dart';
import 'package:ridebuddy/widgets/ride/need_post_card.dart';

class NeedsInboxScreen extends ConsumerStatefulWidget {
  const NeedsInboxScreen({super.key});

  @override
  ConsumerState<NeedsInboxScreen> createState() => _NeedsInboxScreenState();
}

class _NeedsInboxScreenState extends ConsumerState<NeedsInboxScreen> {
  late Future<List<NeedInboxItem>> _inbox;
  late Future<List<RideRequest>> _myNeeds;
  bool _offering = false;
  String? _loadedForUserId;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    final repo = ref.read(rideRepositoryProvider);
    _inbox = repo.needsInbox();
    _myNeeds = repo.myNeeds();
    _loadedForUserId = ref.read(authStateProvider).userId;
  }

  Future<void> _refresh() async {
    setState(_reload);
    await Future.wait([_inbox, _myNeeds]);
  }

  Future<void> _openAndRefresh(String location) async {
    await context.push(location);
    if (mounted) await _refresh();
  }

  Future<void> _offer(NeedInboxItem item) async {
    setState(() => _offering = true);
    try {
      await ref.read(rideRepositoryProvider).offerSeat(
            requestId: item.request.id,
            rideId: item.suggestedRideId,
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
    ref.listen<String?>(authStateProvider.select((s) => s.userId), (prev, next) {
      if (prev == next || next == _loadedForUserId) return;
      setState(_reload);
    });

    ref.listen<int>(rideDataRevisionProvider, (prev, next) {
      if (prev == next) return;
      _refresh();
    });

    return SkyScaffold(
      appBar: AppBar(title: const Text('As a host')),
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Text(
              'Co-riders asking for a seat on your routes, plus asks you posted.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.inkMuted),
            ),
            const SizedBox(height: 18),
            const SectionLabel('Seat requests near you'),
            const SizedBox(height: 10),
            FutureBuilder<List<NeedInboxItem>>(
              future: _inbox,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const SoftPanel(child: LinearProgressIndicator());
                }
                if (snap.hasError) {
                  return SoftPanel(
                    child: EmptyState(
                      title: 'Couldn’t load inbox',
                      subtitle: ref.read(apiClientProvider).messageFrom(snap.error!),
                      actionLabel: 'Retry',
                      onAction: _refresh,
                    ),
                  );
                }
                final list = snap.data ?? [];
                if (list.isEmpty) {
                  return SoftPanel(
                    child: EmptyState(
                      title: 'No seat requests nearby',
                      subtitle: 'Offer an open ride to see co-riders asking for a seat on your route',
                      actionLabel: "I'm offering",
                      onAction: () => _openAndRefresh('/ride/post'),
                    ),
                  );
                }
                return Column(
                  children: list.map((item) {
                    final r = item.request;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: NeedPostCard(
                        need: r,
                        subtitleExtra: '~${item.detourKm.toStringAsFixed(1)} km corridor',
                        footer: Align(
                          alignment: Alignment.centerRight,
                          child: item.alreadyOffered
                              ? Text(
                                  'Offer sent',
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                        color: AppTheme.brandBlue,
                                      ),
                                )
                              : FilledButton(
                                  onPressed: _offering ? null : () => _offer(item),
                                  child: const Text('Offer my seat'),
                                ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(child: SectionLabel('My requests')),
                TextButton(
                  onPressed: () => _openAndRefresh('/ride/needs/new'),
                  child: const Text('New request'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            FutureBuilder<List<RideRequest>>(
              future: _myNeeds,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const SoftPanel(child: LinearProgressIndicator());
                }
                if (snap.hasError) {
                  return SoftPanel(
                    child: EmptyState(
                      title: 'Couldn’t load requests',
                      subtitle: ref.read(apiClientProvider).messageFrom(snap.error!),
                      actionLabel: 'Retry',
                      onAction: _refresh,
                    ),
                  );
                }
                final list = snap.data ?? [];
                if (list.isEmpty) {
                  return SoftPanel(
                    child: EmptyState(
                      title: 'No requests yet',
                      subtitle: 'Post when you need a seat — hosts can offer',
                      actionLabel: 'New request',
                      onAction: () => _openAndRefresh('/ride/needs/new'),
                    ),
                  );
                }
                return Column(
                  children: list.map((r) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: NeedPostCard(
                        need: r,
                        isOwner: true,
                        showPoster: false,
                        showChevron: true,
                        statusLabel: r.status,
                        onTap: () => _openAndRefresh('/ride/need/${r.id}'),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
