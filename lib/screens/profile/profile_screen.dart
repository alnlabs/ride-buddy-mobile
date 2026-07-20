import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ridebuddy/models/models.dart';
import 'package:ridebuddy/providers/auth_provider.dart';
import 'package:ridebuddy/services/api_client.dart';
import 'package:ridebuddy/services/home_spotlight_service.dart';
import 'package:ridebuddy/theme/app_theme.dart';
import 'package:ridebuddy/widgets/common/error_view.dart';
import 'package:ridebuddy/widgets/common/loading_skeleton.dart';
import 'package:ridebuddy/widgets/common/ui_kit.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final auth = ref.watch(authStateProvider);

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
              const SectionLabel('App'),
              const SizedBox(height: 10),
              const _TipsSettingsPanel(),
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

class _TipsSettingsPanel extends ConsumerStatefulWidget {
  const _TipsSettingsPanel();

  @override
  ConsumerState<_TipsSettingsPanel> createState() => _TipsSettingsPanelState();
}

class _TipsSettingsPanelState extends ConsumerState<_TipsSettingsPanel> {
  bool? _enabled;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final enabled = await ref.read(homeSpotlightServiceProvider).tipsEnabled();
    if (!mounted) return;
    setState(() => _enabled = enabled);
  }

  @override
  Widget build(BuildContext context) {
    return SoftPanel(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            title: const Text('Show daily tip or quote on Home'),
            subtitle: const Text('Popup once per day, then pinned on Home'),
            value: _enabled ?? true,
            onChanged: _enabled == null
                ? null
                : (v) async {
                    await ref.read(homeSpotlightServiceProvider).setTipsEnabled(v);
                    setState(() => _enabled = v);
                  },
          ),
          const Divider(height: 1),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            leading: const Icon(Icons.lightbulb_outline_rounded, color: AppTheme.brandOrange),
            title: const Text('Browse tips & quotes'),
            subtitle: const Text('App, safety, manners, co-riders & quotes'),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.inkMuted),
            onTap: () => context.push('/tips'),
          ),
        ],
      ),
    );
  }
}
