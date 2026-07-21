import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ridebuddy/models/models.dart';
import 'package:ridebuddy/models/trip_guidelines.dart';
import 'package:ridebuddy/providers/auth_provider.dart';
import 'package:ridebuddy/services/api_client.dart';
import 'package:ridebuddy/services/chat_repository.dart';
import 'package:ridebuddy/services/ride_repository.dart';
import 'package:ridebuddy/widgets/common/empty_state.dart';
import 'package:ridebuddy/widgets/common/error_view.dart';
import 'package:ridebuddy/widgets/common/loading_skeleton.dart';
import 'package:ridebuddy/widgets/common/ui_kit.dart';
import 'package:ridebuddy/theme/app_theme.dart';
import 'package:ridebuddy/widgets/trip/trip_guidelines_sheet.dart';
import 'package:ridebuddy/providers/chat_provider.dart';

final myTripsProvider = FutureProvider.autoDispose<List<Booking>>((ref) {
  ref.watch(authStateProvider.select((s) => s.userId));
  return ref.read(rideRepositoryProvider).myBookings();
});

class MyTripsScreen extends ConsumerWidget {
  const MyTripsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myTripsProvider);
    return SkyScaffold(
      appBar: AppBar(title: const Text('As a co-rider')),
      child: async.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(20),
          child: LoadingSkeleton(),
        ),
        error: (e, _) => ErrorView(
          message: ref.read(apiClientProvider).messageFrom(e),
          onRetry: () => ref.invalidate(myTripsProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: SoftPanel(
                child: EmptyState(
                  title: 'No trips yet',
                  subtitle: 'Search and book a ride',
                  actionLabel: 'Find a ride',
                  onAction: () => context.push('/ride/search'),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _TripCard(booking: list[i]),
          );
        },
      ),
    );
  }
}

class _TripCard extends ConsumerWidget {
  const _TripCard({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = booking.status == 'requested' || booking.status == 'accepted';
    return SoftPanel(
      onTap: () => context.push('/ride/detail/${booking.rideId}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${booking.rideOriginLabel ?? ''} → ${booking.rideDestinationLabel ?? ''}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            '${_statusLabel(booking.status)} · ${booking.paymentMethod} · ₹${booking.amount.toStringAsFixed(0)}'
            '${booking.departAt != null ? ' · ${DateFormat.MMMd().add_jm().format(booking.departAt!)}' : ''}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted),
          ),
          if (active) ...[
            const SizedBox(height: 12),
            FutureBuilder<TripGuidelines>(
              future: ref.read(rideRepositoryProvider).tripGuidelinesForBooking(booking.id),
              builder: (context, snap) {
                if (!snap.hasData) return const SizedBox.shrink();
                return TripGuidelinesBanner(guidelines: snap.data!, compact: true);
              },
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () async {
                  try {
                    final conv = await ref.read(chatRepositoryProvider).open(bookingId: booking.id);
                    ref.invalidate(chatInboxProvider);
                    if (context.mounted) context.push('/chat/${conv.id}');
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(ref.read(apiClientProvider).messageFrom(e))),
                    );
                  }
                },
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                label: const Text('Message host'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _statusLabel(String status) {
    switch (status) {
      case 'requested':
        return 'Pending host';
      case 'accepted':
        return 'Confirmed';
      case 'rejected':
        return 'Declined';
      case 'cancelled':
        return 'Cancelled';
      case 'completed':
        return 'Completed';
      default:
        return status;
    }
  }
}
