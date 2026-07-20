import 'package:flutter/material.dart';
import 'package:ridebuddy/models/home_spotlight.dart';
import 'package:ridebuddy/theme/app_theme.dart';
import 'package:ridebuddy/widgets/common/ui_kit.dart';
import 'package:ridebuddy/widgets/tips/app_tip_dialog.dart';

/// Pinned daily tip/quote on Home after the popup is dismissed.
class HomeSpotlightCard extends StatelessWidget {
  const HomeSpotlightCard({
    super.key,
    required this.spotlight,
    required this.onDismiss,
    required this.onOpen,
  });

  final HomeSpotlight spotlight;
  final VoidCallback onDismiss;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return SoftPanel(
      onTap: onOpen,
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.brandOrange.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(iconForSpotlight(spotlight.icon), color: AppTheme.brandOrange, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  spotlightKindLabel(spotlight),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppTheme.brandOrange,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                if (spotlight.isTip) ...[
                  Text(spotlight.title, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    spotlight.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ] else ...[
                  Text(
                    spotlight.body,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                          height: 1.35,
                        ),
                  ),
                  if (spotlight.author != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '— ${spotlight.author}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.inkMuted),
                    ),
                  ],
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'Hide for today',
            onPressed: onDismiss,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close_rounded, size: 20, color: AppTheme.inkMuted),
          ),
        ],
      ),
    );
  }
}
