import 'package:flutter/material.dart';
import 'package:ridebuddy/services/routing_service.dart';
import 'package:ridebuddy/theme/app_theme.dart';
import 'package:ridebuddy/widgets/common/ui_kit.dart';

/// Selectable Fastest / Alt route chips — outside the map, single compact row (no scroll).
class RouteAlternativesBar extends StatelessWidget {
  const RouteAlternativesBar({
    super.key,
    required this.routes,
    required this.selectedIndex,
    required this.onSelected,
    this.onRefresh,
    this.infoTitle,
    this.infoMessage,
  });

  final List<DriveRoute> routes;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback? onRefresh;
  final String? infoTitle;
  final String? infoMessage;

  @override
  Widget build(BuildContext context) {
    if (routes.isEmpty) return const SizedBox.shrink();

    final selected =
        selectedIndex >= 0 && selectedIndex < routes.length ? routes[selectedIndex] : routes.first;

    return SoftPanel(
      padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
      child: Row(
        children: [
          Expanded(
            child: routes.length > 1
                ? SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (var i = 0; i < routes.length; i++)
                          Padding(
                            padding: EdgeInsets.only(right: i == routes.length - 1 ? 0 : 6),
                            child: ChoiceChip(
                              label: Text(
                                routes[i].chipLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: i == selectedIndex ? Colors.white : AppTheme.ink,
                                ),
                              ),
                              selected: i == selectedIndex,
                              selectedColor: AppTheme.brandBlue,
                              backgroundColor: AppTheme.surface,
                              onSelected: (_) => onSelected(i),
                              showCheckmark: false,
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                            ),
                          ),
                      ],
                    ),
                  )
                : Row(
                    children: [
                      Icon(
                        selected.usesLiveTraffic ? Icons.traffic_rounded : Icons.route_rounded,
                        size: 16,
                        color: AppTheme.brandBlue,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          selected.chipLabel,
                          style: Theme.of(context).textTheme.labelLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
          ),
          if (infoTitle != null && infoMessage != null)
            IconButton(
              tooltip: infoTitle,
              onPressed: () {
                showModalBottomSheet<void>(
                  context: context,
                  showDragHandle: true,
                  builder: (ctx) => Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(infoTitle!, style: Theme.of(ctx).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(infoMessage!, style: Theme.of(ctx).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.info_outline_rounded, size: 18, color: AppTheme.inkMuted),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
          if (onRefresh != null)
            IconButton(
              tooltip: 'Refresh route',
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
        ],
      ),
    );
  }
}
