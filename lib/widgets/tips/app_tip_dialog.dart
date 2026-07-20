import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ridebuddy/models/home_spotlight.dart';
import 'package:ridebuddy/theme/app_theme.dart';

IconData iconForSpotlight(String name) {
  switch (name) {
    case 'place':
      return Icons.place_outlined;
    case 'share':
      return Icons.ios_share_rounded;
    case 'hail':
      return Icons.hail_rounded;
    case 'airline_seat_recline_extra':
      return Icons.airline_seat_recline_extra_rounded;
    case 'payments':
      return Icons.payments_outlined;
    case 'shield':
      return Icons.shield_outlined;
    case 'schedule':
      return Icons.schedule_rounded;
    case 'chat':
      return Icons.chat_bubble_outline_rounded;
    case 'connect':
      return Icons.handshake_outlined;
    case 'quote':
      return Icons.format_quote_rounded;
    default:
      return Icons.lightbulb_outline_rounded;
  }
}

String spotlightKindLabel(HomeSpotlight s) {
  if (s.isQuote) return 'Quote of the day';
  return 'Tip of the day';
}

Future<void> showHomeSpotlightDialog(
  BuildContext context, {
  required HomeSpotlight spotlight,
  Future<void> Function()? onClose,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(22, 20, 22, 8),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.brandOrange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(iconForSpotlight(spotlight.icon), color: AppTheme.brandOrange),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    spotlightKindLabel(spotlight),
                    style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                          color: AppTheme.brandOrange,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (spotlight.isTip) ...[
              Text(spotlight.title, style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                spotlight.body,
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(height: 1.45),
              ),
            ] else ...[
              Text(
                spotlight.body,
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              if (spotlight.author != null) ...[
                const SizedBox(height: 10),
                Text(
                  '— ${spotlight.author}',
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted),
                ),
              ],
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await onClose?.call();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Got it'),
          ),
          if (spotlight.ctaLabel != null && spotlight.ctaRoute != null)
            FilledButton(
              onPressed: () async {
                await onClose?.call();
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                ctx.go(spotlight.ctaRoute!);
              },
              child: Text(spotlight.ctaLabel!),
            ),
        ],
      );
    },
  );
}
