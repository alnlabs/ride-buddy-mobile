import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ridebuddy/models/models.dart';
import 'package:ridebuddy/theme/app_theme.dart';
import 'package:ridebuddy/widgets/common/poster_identity.dart';
import 'package:ridebuddy/widgets/common/ui_kit.dart';
import 'package:ridebuddy/widgets/maps/place_route_label.dart';

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
    final comfort = ride.comfortRide ? ' · Comfort' : '';

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (ride.poster != null) ...[
          PosterIdentity(
            poster: ride.poster!,
            roleBadge: 'Host',
            dense: compact,
          ),
          SizedBox(height: compact ? 10 : 12),
        ],
        PlaceRouteLabel.route(
          originTitle: ride.originTitle(isOwner: isOwner),
          destinationTitle: ride.destinationTitle(isOwner: isOwner),
          originFull: ride.originFullAddress ?? ride.originLabel,
          destinationFull: ride.destinationFullAddress ?? ride.destinationLabel,
          style: compact
              ? Theme.of(context).textTheme.titleMedium
              : Theme.of(context).textTheme.titleLarge,
        ),
        SizedBox(height: compact ? 8 : 10),
        Text(
          '$when · $seats$comfort',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: compact ? AppTheme.inkMuted : AppTheme.ink,
              ),
        ),
        const SizedBox(height: 10),
        FareChip(
          pricePerSeat: ride.pricePerSeat,
          compact: compact && !emphasizeFare,
          emphasize: emphasizeFare,
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

    if (showChevron) {
      return SoftPanel(
        onTap: onTap,
        child: Row(
          children: [
            Expanded(child: body),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.inkMuted),
          ],
        ),
      );
    }

    return SoftPanel(onTap: onTap, child: body);
  }
}
