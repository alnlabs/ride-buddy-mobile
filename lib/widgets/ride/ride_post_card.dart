import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ridebuddy/models/models.dart';
import 'package:ridebuddy/theme/app_theme.dart';
import 'package:ridebuddy/widgets/common/poster_identity.dart';
import 'package:ridebuddy/widgets/common/ui_kit.dart';

/// Consistent open-ride row / hero for lists and detail.
class RidePostCard extends StatelessWidget {
  const RidePostCard({
    super.key,
    required this.ride,
    this.onTap,
    this.isOwner = false,
    this.compact = true,
    this.showChevron = false,
    this.badge,
    this.footer,
    this.emphasizeFare = false,
  });

  final Ride ride;
  final VoidCallback? onTap;
  final bool isOwner;
  final bool compact;
  final bool showChevron;
  final Widget? badge;
  final Widget? footer;
  final bool emphasizeFare;

  @override
  Widget build(BuildContext context) {
    final when = DateFormat.MMMd().add_jm().format(ride.departAt);
    final seats = '${ride.availableSeats} seat${ride.availableSeats == 1 ? '' : 's'}';
    final theme = Theme.of(context);

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.brandOrange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isOwner ? 'Offering' : 'Open seat',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppTheme.brandOrange,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Spacer(),
            FareChip(
              pricePerSeat: ride.pricePerSeat,
              compact: true,
              emphasize: emphasizeFare,
            ),
          ],
        ),
        if (ride.poster != null) ...[
          SizedBox(height: compact ? 10 : 12),
          PosterIdentity(
            poster: ride.poster!,
            roleBadge: 'Host',
            dense: compact,
          ),
        ],
        SizedBox(height: compact ? 12 : 14),
        _RouteStrip(
          from: ride.originTitle(isOwner: isOwner),
          to: ride.destinationTitle(isOwner: isOwner),
          accent: AppTheme.brandOrange,
          compact: compact,
        ),
        SizedBox(height: compact ? 10 : 12),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _MetaChip(icon: Icons.schedule_rounded, label: when),
            _MetaChip(icon: Icons.event_seat_rounded, label: seats),
            if (ride.comfortRide)
              const _MetaChip(icon: Icons.airline_seat_recline_extra_rounded, label: 'Comfort'),
          ],
        ),
        if (badge != null) ...[
          const SizedBox(height: 10),
          badge!,
        ],
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
                color: AppTheme.brandOrange,
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

class _RouteStrip extends StatelessWidget {
  const _RouteStrip({
    required this.from,
    required this.to,
    required this.accent,
    required this.compact,
  });

  final String from;
  final String to;
  final Color accent;
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
            Icon(Icons.trip_origin_rounded, size: 16, color: accent),
            Container(
              width: 2,
              height: compact ? 18 : 22,
              margin: const EdgeInsets.symmetric(vertical: 3),
              color: accent.withOpacity(0.35),
            ),
            Icon(Icons.flag_rounded, size: 16, color: accent),
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

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

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
