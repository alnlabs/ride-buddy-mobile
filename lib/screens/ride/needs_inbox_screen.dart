import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ridebuddy/models/models.dart';
import 'package:ridebuddy/services/api_client.dart';
import 'package:ridebuddy/services/ride_repository.dart';
import 'package:ridebuddy/theme/app_theme.dart';
import 'package:ridebuddy/widgets/common/empty_state.dart';
import 'package:ridebuddy/widgets/common/poster_identity.dart';
import 'package:ridebuddy/widgets/common/ui_kit.dart';

class NeedsInboxScreen extends ConsumerStatefulWidget {
  const NeedsInboxScreen({super.key});

  @override
  ConsumerState<NeedsInboxScreen> createState() => _NeedsInboxScreenState();
}

class _NeedsInboxScreenState extends ConsumerState<NeedsInboxScreen> {
  late Future<List<NeedInboxItem>> _inbox;
  late Future<List<RideRequest>> _myNeeds;
  bool _offering = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    final repo = ref.read(rideRepositoryProvider);
    _inbox = repo.needsInbox();
    _myNeeds = repo.myNeeds();
  }

  Future<void> _refresh() async {
    setState(_reload);
    await Future.wait([_inbox, _myNeeds]);
  }

  Future<void> _offer(NeedInboxItem item) async {
    setState(() => _offering = true);
    try {
      await ref.read(rideRepositoryProvider).offerSeat(
            requestId: item.request.id,
            rideId: item.suggestedRideId,
          );
      if (!mounted) return;
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

  String _short(String label) {
    if (label.length <= 32) return label;
    return '${label.substring(0, 30)}…';
  }

  @override
  Widget build(BuildContext context) {
    return SkyScaffold(
      appBar: AppBar(title: const Text('Needs')),
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Text(
              'Nearby co-riders who need a seat on your routes, plus your own need posts.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.inkMuted),
            ),
            const SizedBox(height: 18),
            const SectionLabel('Nearby need-a-rides'),
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
                      title: 'No nearby needs',
                      subtitle: 'Post an open ride to see co-riders needing a seat on your route',
                      actionLabel: 'Offer a ride',
                      onAction: () => context.push('/ride/post'),
                    ),
                  );
                }
                return Column(
                  children: list.map((item) {
                    final r = item.request;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SoftPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (r.poster != null) ...[
                              PosterIdentity(poster: r.poster!, roleBadge: 'Needs seat', dense: true),
                              const SizedBox(height: 10),
                            ],
                            Text(
                              '${_short(r.originLabel)} → ${_short(r.destinationLabel)}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${DateFormat.MMMd().add_jm().format(r.departAt)} · '
                              '${r.seatsNeeded} seat${r.seatsNeeded == 1 ? '' : 's'}'
                              '${r.comfortPreferred ? ' · Comfort' : ''}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '~${item.detourKm.toStringAsFixed(1)} km corridor match',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.inkMuted,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Align(
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
                          ],
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
                const Expanded(child: SectionLabel('Your need posts')),
                TextButton(
                  onPressed: () => context.push('/ride/needs/new'),
                  child: const Text('Post need'),
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
                      title: 'Couldn’t load needs',
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
                      title: 'No need posts yet',
                      subtitle: 'Post when you need a seat — hosts can offer',
                      actionLabel: 'Need a ride',
                      onAction: () => context.push('/ride/needs/new'),
                    ),
                  );
                }
                return Column(
                  children: list.map((r) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SoftPanel(
                        onTap: () => context.push('/ride/need/${r.id}'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_short(r.originLabel)} → ${_short(r.destinationLabel)}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${DateFormat.MMMd().add_jm().format(r.departAt)} · ${r.status}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
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
