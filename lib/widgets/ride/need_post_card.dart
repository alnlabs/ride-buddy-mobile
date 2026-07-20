import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ridebuddy/models/models.dart';
import 'package:ridebuddy/theme/app_theme.dart';
import 'package:ridebuddy/widgets/common/poster_identity.dart';
import 'package:ridebuddy/widgets/common/ui_kit.dart';
import 'package:ridebuddy/widgets/maps/place_route_label.dart';

/// Consistent seat-need row / hero for lists and detail.
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
    final seats =
        'Needs ${need.seatsNeeded} seat${need.seatsNeeded == 1 ? '' : 's'}';
    final comfort = need.comfortPreferred ? ' · Comfort' : '';
    final status = statusLabel != null ? ' · $statusLabel' : '';
    final extra = subtitleExtra != null ? ' · $subtitleExtra' : '';

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showPoster && need.poster != null) ...[
          PosterIdentity(
            poster: need.poster!,
            roleBadge: 'Needs seat',
            dense: compact,
          ),
          SizedBox(height: compact ? 10 : 12),
        ],
        PlaceRouteLabel.route(
          originTitle: need.originTitle(isOwner: isOwner),
          destinationTitle: need.destinationTitle(isOwner: isOwner),
          originFull: need.originFullAddress ?? need.originLabel,
          destinationFull: need.destinationFullAddress ?? need.destinationLabel,
          style: compact
              ? Theme.of(context).textTheme.titleMedium
              : Theme.of(context).textTheme.titleLarge,
        ),
        SizedBox(height: compact ? 8 : 10),
        Text(
          '$when · $seats$comfort$status$extra',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: compact ? AppTheme.inkMuted : AppTheme.ink,
              ),
        ),
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
