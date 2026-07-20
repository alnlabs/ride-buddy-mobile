import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ridebuddy/models/models.dart';
import 'package:ridebuddy/theme/app_theme.dart';
import 'package:ridebuddy/widgets/common/poster_identity.dart';
import 'package:ridebuddy/widgets/common/ui_kit.dart';

/// Consistent seat-ask row / hero for lists and detail.
class NeedPostCard extends StatelessWidget {
  const NeedPostCard({
    super.key,
    required this.need,
    this.onTap,
    this.isOwner = false,
    this.compact = true,
    this.showChevron = false,
    this.showPoster = true,
    this.statusLabel,
    this.subtitleExtra,
    this.footer,
  });

  final RideRequest need;
  final VoidCallback? onTap;
  final bool isOwner;
  final bool compact;
  final bool showChevron;
  final bool showPoster;
  final String? statusLabel;
  final String? subtitleExtra;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final when = DateFormat.MMMd().add_jm().format(need.departAt);
    final seats = '${need.seatsNeeded} seat${need.seatsNeeded == 1 ? '' : 's'}';
    final theme = Theme.of(context);
    final status = statusLabel?.trim();

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.brandBlue.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isOwner ? 'My request' : 'Looking for seat',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppTheme.brandBlue,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (status != null && status.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                status,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppTheme.inkMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
        if (showPoster && need.poster != null) ...[
          SizedBox(height: compact ? 10 : 12),
          PosterIdentity(
            poster: need.poster!,
            roleBadge: 'Co-rider',
            dense: compact,
          ),
        ],
        SizedBox(height: compact ? 12 : 14),
        _AskRouteStrip(
          from: need.originTitle(isOwner: isOwner),
          to: need.destinationTitle(isOwner: isOwner),
          compact: compact,
        ),
        SizedBox(height: compact ? 10 : 12),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _AskMetaChip(icon: Icons.schedule_rounded, label: when),
            _AskMetaChip(icon: Icons.event_seat_rounded, label: seats),
            if (need.comfortPreferred)
              const _AskMetaChip(icon: Icons.airline_seat_recline_extra_rounded, label: 'Comfort'),
            if (subtitleExtra != null && subtitleExtra!.trim().isNotEmpty)
              _AskMetaChip(icon: Icons.route_rounded, label: subtitleExtra!.trim()),
          ],
        ),
        if (footer != null) ...[
          const SizedBox(height: 12),
          footer!,
        ],
      ],
    );

    return SoftPanel(
      onTap: onTap,
      padding: EdgeInsets.fromLTRB(compact ? 12 : 14, compact ? 12 : 14, showChevron ? 8 : (compact ? 12 : 14), compact ? 12 : 14),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: AppTheme.brandBlue,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: body),
            if (showChevron)
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.chevron_right_rounded, color: AppTheme.inkMuted),
              ),
          ],
        ),
      ),
    );
  }
}

class _AskRouteStrip extends StatelessWidget {
  const _AskRouteStrip({
    required this.from,
    required this.to,
    required this.compact,
  });

  final String from;
  final String to;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final titleStyle = (compact
            ? Theme.of(context).textTheme.titleSmall
            : Theme.of(context).textTheme.titleMedium)
        ?.copyWith(fontWeight: FontWeight.w800, height: 1.25);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            const Icon(Icons.trip_origin_rounded, size: 16, color: AppTheme.brandBlue),
            Container(
              width: 2,
              height: compact ? 18 : 22,
              margin: const EdgeInsets.symmetric(vertical: 3),
              color: AppTheme.brandBlue.withOpacity(0.35),
            ),
            const Icon(Icons.flag_rounded, size: 16, color: AppTheme.brandBlue),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('From', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.inkMuted)),
              Text(from, maxLines: 2, overflow: TextOverflow.ellipsis, style: titleStyle),
              SizedBox(height: compact ? 8 : 10),
              Text('To', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.inkMuted)),
              Text(to, maxLines: 2, overflow: TextOverflow.ellipsis, style: titleStyle),
            ],
          ),
        ),
      ],
    );
  }
}

class _AskMetaChip extends StatelessWidget {
  const _AskMetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.skyTop.withOpacity(0.65),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.inkMuted),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppTheme.ink,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
