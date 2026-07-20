import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ridebuddy/services/home_spotlight_service.dart';
import 'package:ridebuddy/theme/app_theme.dart';
import 'package:ridebuddy/widgets/common/ui_kit.dart';
import 'package:ridebuddy/widgets/tips/app_tip_dialog.dart';

class TipsScreen extends ConsumerWidget {
  const TipsScreen({super.key});

  static const _categories = [
    ('app', 'Using the app'),
    ('safety', 'Safety'),
    ('manners', 'Ride etiquette'),
    ('connect', 'Co-riders'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(homeSpotlightServiceProvider);

    return SkyScaffold(
      appBar: AppBar(title: const Text('Tips & quotes')),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Text(
            'One tip or quote pops up on Home each day, then stays pinned until you hide it.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.inkMuted),
          ),
          const SizedBox(height: 16),
          for (final (id, label) in _categories) ...[
            SectionLabel(label),
            const SizedBox(height: 10),
            for (final tip in service.tipsForCategory(id))
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SoftPanel(
                  onTap: () => showHomeSpotlightDialog(context, spotlight: tip),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(iconForSpotlight(tip.icon), color: AppTheme.brandBlue, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tip.title, style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 4),
                            Text(
                              tip.body,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: AppTheme.inkMuted),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
          ],
          const SectionLabel('Quotes'),
          const SizedBox(height: 10),
          for (final quote in service.allQuotes())
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SoftPanel(
                onTap: () => showHomeSpotlightDialog(context, spotlight: quote),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(iconForSpotlight(quote.icon), color: AppTheme.brandOrange, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            quote.body,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontStyle: FontStyle.italic,
                                ),
                          ),
                          if (quote.author != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              '— ${quote.author}',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppTheme.inkMuted,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppTheme.inkMuted),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
