import 'package:flutter/material.dart';
import 'package:ridebuddy/services/place_label_formatter.dart';
import 'package:ridebuddy/theme/app_theme.dart';

/// Shows public/private place title with optional expand to full address.
class PlaceRouteLabel extends StatefulWidget {
  const PlaceRouteLabel({
    super.key,
    required this.title,
    this.fullAddress,
    this.maxTitleLength,
    this.style,
    this.dense = false,
  });

  final String title;
  final String? fullAddress;
  final int? maxTitleLength;
  final TextStyle? style;
  final bool dense;

  /// Convenience for origin → destination rows.
  static Widget route({
    required String originTitle,
    required String destinationTitle,
    String? originFull,
    String? destinationFull,
    TextStyle? style,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: PlaceRouteLabel(
            title: originTitle,
            fullAddress: originFull,
            style: style,
            dense: true,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Text('→', style: style),
        ),
        Expanded(
          child: PlaceRouteLabel(
            title: destinationTitle,
            fullAddress: destinationFull,
            style: style,
            dense: true,
          ),
        ),
      ],
    );
  }

  @override
  State<PlaceRouteLabel> createState() => _PlaceRouteLabelState();
}

class _PlaceRouteLabelState extends State<PlaceRouteLabel> {
  bool _expanded = false;

  String get _title {
    final t = widget.title.trim().isEmpty ? 'Place' : widget.title.trim();
    final max = widget.maxTitleLength;
    if (max == null || t.length <= max) return t;
    return PlaceLabelFormatter.shortenStoredLabel(t);
  }

  String? get _full {
    final f = widget.fullAddress?.trim();
    if (f == null || f.isEmpty) return null;
    if (f == widget.title.trim()) return null;
    return f;
  }

  @override
  Widget build(BuildContext context) {
    final full = _full;
    final titleStyle = widget.style ?? Theme.of(context).textTheme.bodyMedium;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _expanded && full != null ? full : _title,
                maxLines: _expanded ? 4 : (widget.dense ? 2 : 2),
                overflow: TextOverflow.ellipsis,
                style: titleStyle,
              ),
            ),
            if (full != null)
              IconButton(
                tooltip: _expanded ? 'Show short name' : 'Show full address',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: Icon(
                  _expanded ? Icons.unfold_less_rounded : Icons.unfold_more_rounded,
                  size: 18,
                  color: AppTheme.inkMuted,
                ),
                onPressed: () => setState(() => _expanded = !_expanded),
              ),
          ],
        ),
      ],
    );
  }
}

/// Pick display title: private for owner when present, else public short / legacy.
String placeDisplayTitle({
  required String publicShort,
  String? privateLabel,
  required bool isOwner,
}) {
  if (isOwner && privateLabel != null && privateLabel.trim().isNotEmpty) {
    return privateLabel.trim();
  }
  final p = publicShort.trim();
  if (p.isEmpty) return 'Place';
  // Legacy long labels stored as originLabel before this feature.
  if (p.contains(',') && p.length > 48) {
    return PlaceLabelFormatter.shortenStoredLabel(p);
  }
  return p;
}
