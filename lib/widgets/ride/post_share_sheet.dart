import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ridebuddy/services/whatsapp_share.dart';
import 'package:ridebuddy/theme/app_theme.dart';
import 'package:ridebuddy/widgets/common/ui_kit.dart';
import 'package:share_plus/share_plus.dart';

Future<void> showPostShareSheet(
  BuildContext context, {
  required String title,
  required String text,
  required String link,
}) async {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppTheme.surfaceElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.line,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(ctx).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              'Preview of the message people will see',
              style: Theme.of(ctx).textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.42,
              ),
              child: SoftPanel(
                padding: const EdgeInsets.all(14),
                child: SingleChildScrollView(
                  child: SelectableText(
                    trimmed,
                    style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.ink,
                          height: 1.45,
                        ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Share on WhatsApp',
              icon: Icons.chat_rounded,
              backgroundColor: const Color(0xFF25D366),
              onPressed: () async {
                await shareTextToWhatsApp(trimmed);
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: trimmed));
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Message copied')),
                        );
                      }
                    },
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('Copy text'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: link.isEmpty
                        ? null
                        : () async {
                            await Clipboard.setData(ClipboardData(text: link));
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(content: Text('Link copied')),
                              );
                            }
                          },
                    icon: const Icon(Icons.link_rounded, size: 18),
                    label: const Text('Copy link'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () async {
                await SharePlus.instance.share(ShareParams(text: trimmed));
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('More apps…'),
            ),
          ],
        ),
      );
    },
  );
}
