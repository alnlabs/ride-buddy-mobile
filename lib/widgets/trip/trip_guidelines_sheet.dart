import 'package:flutter/material.dart';
import 'package:ridebuddy/models/trip_guidelines.dart';
import 'package:ridebuddy/theme/app_theme.dart';
import 'package:ridebuddy/widgets/common/ui_kit.dart';

Future<void> showTripGuidelinesSheet(
  BuildContext context, {
  required TripGuidelines guidelines,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppTheme.surfaceElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => TripGuidelinesSheet(guidelines: guidelines),
  );
}

class TripGuidelinesSheet extends StatelessWidget {
  const TripGuidelinesSheet({super.key, required this.guidelines});

  final TripGuidelines guidelines;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.82,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (ctx, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
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
              Text(guidelines.heading, style: Theme.of(ctx).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                guidelines.intro,
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(color: AppTheme.inkMuted, height: 1.45),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    if (guidelines.hasSharedInterests) ...[
                      _SharedInterestsRow(interests: guidelines.sharedInterests),
                      const SizedBox(height: 14),
                    ],
                    const SectionLabel('For everyone'),
                    const SizedBox(height: 8),
                    ...guidelines.common.map((g) => _GuidelineTile(item: g)),
                    const SizedBox(height: 18),
                    const SectionLabel('What to expect'),
                    const SizedBox(height: 8),
                    ...guidelines.expectations.map((g) => _GuidelineTile(item: g, accent: AppTheme.brandOrange)),
                    if (guidelines.conversationHints.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      SectionLabel(
                        guidelines.hasSharedInterests ? 'If you both feel like talking' : 'Conversation ideas',
                      ),
                      const SizedBox(height: 8),
                      if (!guidelines.viewerHasInterests)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            'Add interests on your profile for better suggestions over time.',
                            style: Theme.of(ctx).textTheme.bodySmall,
                          ),
                        ),
                      ...guidelines.conversationHints.map((h) => _HintTile(hint: h)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Compact entry point — tap to open the full sheet.
class TripGuidelinesBanner extends StatelessWidget {
  const TripGuidelinesBanner({
    super.key,
    required this.guidelines,
    this.compact = false,
  });

  final TripGuidelines guidelines;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final subtitle = guidelines.hasSharedInterests
        ? 'You share ${guidelines.sharedInterests.length} interest${guidelines.sharedInterests.length == 1 ? '' : 's'} — chat optional'
        : guidelines.isDuringTrip
            ? 'Pickup, payment & what to expect'
            : 'Before you ride — practical & optional connection tips';

    return SoftPanel(
      onTap: () => showTripGuidelinesSheet(context, guidelines: guidelines),
      padding: compact ? const EdgeInsets.all(12) : const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.brandBlue.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              guidelines.isDuringTrip ? Icons.route_rounded : Icons.menu_book_outlined,
              color: AppTheme.brandBlue,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  guidelines.heading,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
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

class _SharedInterestsRow extends StatelessWidget {
  const _SharedInterestsRow({required this.interests});

  final List<String> interests;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: interests
          .map(
            (tag) => Chip(
              label: Text(tag),
              backgroundColor: AppTheme.brandBlue.withOpacity(0.1),
              labelStyle: const TextStyle(color: AppTheme.brandBlue, fontWeight: FontWeight.w600),
              side: BorderSide.none,
              visualDensity: VisualDensity.compact,
            ),
          )
          .toList(),
    );
  }
}

class _GuidelineTile extends StatelessWidget {
  const _GuidelineTile({required this.item, this.accent = AppTheme.brandBlue});

  final GuidelineItem item;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(Icons.check_circle_outline_rounded, size: 18, color: accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  item.body,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HintTile extends StatelessWidget {
  const _HintTile({required this.hint});

  final ConversationHint hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SoftPanel(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(hint.interest, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.brandBlue)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(hint.suggestion, style: Theme.of(context).textTheme.bodySmall),
            ),
          ],
        ),
      ),
    );
  }
}
