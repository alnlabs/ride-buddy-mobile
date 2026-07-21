import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ridebuddy/models/models.dart';
import 'package:ridebuddy/providers/auth_provider.dart';
import 'package:ridebuddy/services/api_client.dart';
import 'package:ridebuddy/services/ride_repository.dart';
import 'package:ridebuddy/theme/app_theme.dart';
import 'package:ridebuddy/widgets/common/empty_state.dart';
import 'package:ridebuddy/widgets/common/ui_kit.dart';

class SchedulesScreen extends ConsumerStatefulWidget {
  const SchedulesScreen({super.key});

  @override
  ConsumerState<SchedulesScreen> createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends ConsumerState<SchedulesScreen> {
  late Future<List<RideSchedule>> _future;
  String? _loadedForUserId;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = ref.read(rideRepositoryProvider).mySchedules();
    _loadedForUserId = ref.read(authStateProvider).userId;
  }

  Future<void> _toggle(RideSchedule s) async {
    try {
      if (s.active) {
        await ref.read(rideRepositoryProvider).pauseSchedule(s.id);
      } else {
        await ref.read(rideRepositoryProvider).resumeSchedule(s.id);
      }
      if (!mounted) return;
      setState(_reload);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ref.read(apiClientProvider).messageFrom(e))),
      );
    }
  }

  Future<void> _cancel(RideSchedule s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Stop schedule?'),
        content: const Text('No new daily posts will be created. Past posts stay for your record.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Stop')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(rideRepositoryProvider).cancelSchedule(s.id);
      if (!mounted) return;
      setState(_reload);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ref.read(apiClientProvider).messageFrom(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(authStateProvider.select((s) => s.userId), (prev, next) {
      if (prev == next || next == _loadedForUserId) return;
      setState(_reload);
    });

    return SkyScaffold(
      appBar: AppBar(title: const Text('My schedules')),
      child: FutureBuilder<List<RideSchedule>>(
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
                  title: 'Couldn’t load schedules',
                  subtitle: ref.read(apiClientProvider).messageFrom(snap.error!),
                  actionLabel: 'Retry',
                  onAction: () => setState(_reload),
                ),
              ),
            );
          }
          final list = snap.data ?? [];
          if (list.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: SoftPanel(
                child: EmptyState(
                  title: 'No recurring schedules',
                  subtitle: 'Choose Recurring when posting a ride or request',
                  icon: Icons.event_repeat_rounded,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final s = list[i];
              return SoftPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          s.kind == 'ride' ? Icons.directions_car_filled_rounded : Icons.hail_rounded,
                          color: AppTheme.brandBlue,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${s.kind == 'ride' ? 'Hosting' : 'Request'} · ${s.frequencyLabel}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: (s.active ? AppTheme.success : AppTheme.inkMuted).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            s.active ? 'Active' : 'Paused',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: s.active ? AppTheme.success : AppTheme.inkMuted,
                                  fontSize: 11,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${s.originLabel} → ${s.destinationLabel}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Depart ${s.departLocalTime}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => _toggle(s),
                          child: Text(s.active ? 'Pause' : 'Resume'),
                        ),
                        TextButton(
                          onPressed: () => _cancel(s),
                          style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
                          child: const Text('Stop'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
