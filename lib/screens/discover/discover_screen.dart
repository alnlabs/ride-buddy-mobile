import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ridebuddy/theme/app_theme.dart';
import 'package:ridebuddy/widgets/common/ui_kit.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SkyScaffold(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Text('Discover', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(
              'Community features beyond your daily commute.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.inkMuted),
            ),
            const SizedBox(height: 22),
            _FeatureCard(
              icon: Icons.work_outline_rounded,
              title: 'Job referrals',
              subtitle: 'Refer coworkers · earn credits',
              onTap: () => context.push('/discover/jobs'),
            ),
            const SizedBox(height: 10),
            _FeatureCard(
              icon: Icons.groups_outlined,
              title: 'Meetups',
              subtitle: 'Interest-based gatherings near you',
              accent: AppTheme.brandOrange,
              onTap: () => context.push('/discover/meetups'),
            ),
            const SizedBox(height: 10),
            _FeatureCard(
              icon: Icons.podcasts_outlined,
              title: 'Rider podcast',
              subtitle: 'Listen on your commute',
              onTap: () => context.push('/discover/podcast'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.accent = AppTheme.brandBlue,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SoftPanel(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppTheme.inkMuted),
        ],
      ),
    );
  }
}
