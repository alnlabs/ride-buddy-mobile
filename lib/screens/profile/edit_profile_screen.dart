import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ridebuddy/providers/auth_provider.dart';
import 'package:ridebuddy/services/api_client.dart';
import 'package:ridebuddy/theme/app_theme.dart';
import 'package:ridebuddy/widgets/common/error_view.dart';
import 'package:ridebuddy/widgets/common/loading_skeleton.dart';
import 'package:ridebuddy/widgets/common/ui_kit.dart';

class EditProfileScreen extends ConsumerWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);

    return SkyScaffold(
      appBar: AppBar(title: const Text('Edit profile')),
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
                    Text('Profile strength', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(
                      'Complete the basics below to make matching and ride posts clearer.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    StrengthBar(value: p.profileStrength),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const SectionLabel('Setup'),
              const SizedBox(height: 10),
              ActionRow(
                icon: Icons.mark_email_read_outlined,
                title: 'Email',
                subtitle: p.emailSetupSubtitle,
                onTap: () => context.push('/profile/email'),
              ),
              const SizedBox(height: 10),
              ActionRow(
                icon: Icons.badge_outlined,
                title: 'Role & company',
                subtitle: p.hasWork ? p.workLine! : 'Shown on every ride or need post',
                onTap: () => context.push('/profile/work'),
              ),
              const SizedBox(height: 10),
              ActionRow(
                icon: Icons.place_outlined,
                title: 'Home & Office',
                subtitle: p.hasPlaces ? 'Saved for commute matching' : 'Add places to match better',
                accent: AppTheme.brandOrange,
                onTap: () => context.push('/profile/places'),
              ),
              const SizedBox(height: 10),
              ActionRow(
                icon: Icons.interests_outlined,
                title: 'Interests',
                subtitle: p.topInterests.isNotEmpty
                    ? 'On posts: ${p.topInterests.take(5).join(', ')}'
                    : p.interests.isEmpty
                        ? 'Add at least 5 · pick top 5 for posts'
                        : 'Pick your top 5 for ride & need posts',
                onTap: () => context.push('/profile/interests'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
