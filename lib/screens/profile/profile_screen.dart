import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ridebuddy/models/models.dart';
import 'package:ridebuddy/providers/auth_provider.dart';
import 'package:ridebuddy/providers/chat_provider.dart';
import 'package:ridebuddy/services/api_client.dart';
import 'package:ridebuddy/services/ride_repository.dart';
import 'package:ridebuddy/theme/app_theme.dart';
import 'package:ridebuddy/widgets/common/error_view.dart';
import 'package:ridebuddy/widgets/common/loading_skeleton.dart';
import 'package:ridebuddy/widgets/common/ui_kit.dart';

final seatRequestCountProvider = FutureProvider.autoDispose<int>((ref) async {
  ref.watch(authStateProvider.select((s) => s.userId));
  try {
    final inbox = await ref.read(rideRepositoryProvider).needsInbox();
    return inbox.length;
  } catch (_) {
    return 0;
  }
});

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final auth = ref.watch(authStateProvider);
    final seatRequests = ref.watch(seatRequestCountProvider).valueOrNull ?? 0;

    return SkyScaffold(
      child: SafeArea(
        child: profile.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(20),
            child: LoadingSkeleton(),
          ),
          error: (e, _) => ErrorView(
            message: ref.read(apiClientProvider).messageFrom(e),
            onRetry: () => ref.invalidate(profileProvider),
          ),
          data: (p) => ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              Row(
                children: [
                  Text('Account', style: Theme.of(context).textTheme.headlineMedium),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Sign out',
                    onPressed: () => ref.read(authStateProvider.notifier).logout(),
                    icon: const Icon(Icons.logout_rounded, color: AppTheme.inkMuted),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _AccountSummaryCard(profile: p, phone: auth.phone),
              const SizedBox(height: 12),
              SoftPanel(
                onTap: () => context.push('/profile/view'),
                child: StrengthBar(value: p.profileStrength),
              ),
              const SizedBox(height: 22),
              const SectionLabel('Profile'),
              const SizedBox(height: 10),
              ActionRow(
                icon: Icons.person_outline_rounded,
                title: 'View profile',
                subtitle: 'See your account details, work, places and interests',
                onTap: () => context.push('/profile/view'),
              ),
              const SizedBox(height: 22),
              const SectionLabel('Ride'),
              const SizedBox(height: 10),
              ActionRow(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Messages',
                subtitle: 'Chat with hosts and co-riders',
                badgeCount: ref.watch(chatUnreadTotalProvider),
                onTap: () => context.push('/chat'),
              ),
              const SizedBox(height: 10),
              ActionRow(
                icon: Icons.confirmation_number_outlined,
                title: 'My trips',
                subtitle: 'Bookings as a co-rider',
                onTap: () => context.push('/ride/trips'),
              ),
              const SizedBox(height: 10),
              ActionRow(
                icon: Icons.inbox_outlined,
                title: 'Seat requests',
                subtitle: 'People asking for a seat on your routes',
                accent: AppTheme.brandOrange,
                badgeCount: seatRequests,
                onTap: () => context.push('/ride/needs'),
              ),
              const SizedBox(height: 10),
              ActionRow(
                icon: Icons.event_repeat_rounded,
                title: 'My schedules',
                subtitle: 'Recurring rides and requests',
                onTap: () => context.push('/ride/schedules'),
              ),
              const SizedBox(height: 10),
              ActionRow(
                icon: Icons.directions_car_outlined,
                title: 'My vehicles',
                subtitle: 'Needed before offering rides',
                onTap: () => context.push('/profile/vehicles'),
              ),
              const SizedBox(height: 22),
              const SectionLabel('App'),
              const SizedBox(height: 10),
              ActionRow(
                icon: Icons.settings_outlined,
                title: 'Settings',
                subtitle: 'Tips, quotes and app preferences',
                onTap: () => context.push('/profile/settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountSummaryCard extends StatelessWidget {
  const _AccountSummaryCard({required this.profile, required this.phone});

  final Profile profile;
  final String? phone;

  @override
  Widget build(BuildContext context) {
    return SoftPanel(
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppTheme.brandBlue.withOpacity(0.12),
            child: Text(
              profile.displayName.isNotEmpty ? profile.displayName[0].toUpperCase() : '?',
              style: const TextStyle(
                color: AppTheme.brandBlue,
                fontWeight: FontWeight.w800,
                fontSize: 24,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.displayName, style: Theme.of(context).textTheme.titleLarge),
                if (profile.employeeVerified)
                  Row(
                    children: [
                      const Icon(Icons.verified_rounded, size: 16, color: AppTheme.brandBlue),
                      const SizedBox(width: 4),
                      Text(
                        'Verified employee',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.brandBlue,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                if (profile.workLine != null)
                  Text(profile.workLine!, style: Theme.of(context).textTheme.bodyMedium),
                if (phone != null) Text(phone!, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
