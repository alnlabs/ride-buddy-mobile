import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ridebuddy/providers/auth_provider.dart';
import 'package:ridebuddy/services/api_client.dart';
import 'package:ridebuddy/theme/app_theme.dart';
import 'package:ridebuddy/widgets/common/error_view.dart';
import 'package:ridebuddy/widgets/common/loading_skeleton.dart';
import 'package:ridebuddy/widgets/common/ui_kit.dart';

class ProfileViewScreen extends ConsumerWidget {
  const ProfileViewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final auth = ref.watch(authStateProvider);

    return SkyScaffold(
      appBar: AppBar(title: const Text('View profile')),
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
              SoftPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: AppTheme.brandBlue.withOpacity(0.12),
                          child: Text(
                            p.displayName.isNotEmpty ? p.displayName[0].toUpperCase() : '?',
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
                              Text(p.displayName, style: Theme.of(context).textTheme.titleLarge),
                              if (p.employeeVerified)
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.verified_rounded,
                                      size: 16,
                                      color: AppTheme.brandBlue,
                                    ),
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
                              if (p.workLine != null)
                                Text(p.workLine!, style: Theme.of(context).textTheme.bodyMedium),
                              if (auth.phone != null)
                                Text(auth.phone!, style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    StrengthBar(value: p.profileStrength),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const SectionLabel('Work'),
              const SizedBox(height: 10),
              _InfoPanel(
                icon: Icons.badge_outlined,
                title: 'Role & company',
                body: p.workLine ?? 'Not added yet',
              ),
              const SizedBox(height: 10),
              _InfoPanel(
                icon: Icons.mark_email_read_outlined,
                title: 'Email status',
                body: p.emailSetupSubtitle,
              ),
              const SizedBox(height: 22),
              const SectionLabel('Places'),
              const SizedBox(height: 10),
              _InfoPanel(
                icon: Icons.home_outlined,
                title: 'Home',
                body: p.homeLabel ?? 'Not added yet',
              ),
              const SizedBox(height: 10),
              _InfoPanel(
                icon: Icons.business_outlined,
                title: 'Office',
                body: p.officeLabel ?? 'Not added yet',
              ),
              const SizedBox(height: 22),
              const SectionLabel('Interests'),
              const SizedBox(height: 10),
              _InfoPanel(
                icon: Icons.interests_outlined,
                title: 'Top interests',
                body: p.topInterests.isNotEmpty
                    ? p.topInterests.join(', ')
                    : p.interests.isNotEmpty
                        ? p.interests.take(5).join(', ')
                        : 'Not added yet',
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: () => context.push('/profile/edit'),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return SoftPanel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.brandBlue.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.brandBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(body, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
