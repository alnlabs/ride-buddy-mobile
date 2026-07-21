import 'package:flutter/material.dart';
import 'package:ridebuddy/models/models.dart';
import 'package:ridebuddy/theme/app_theme.dart';

/// Compact identity strip for host / co-rider posts: name, role · company, top interests.
class PosterIdentity extends StatelessWidget {
  const PosterIdentity({
    super.key,
    required this.poster,
    this.roleBadge,
    this.dense = false,
    this.maxInterests = 5,
    this.showName = true,
  });

  final PosterCard poster;
  final String? roleBadge;
  final bool dense;
  final int maxInterests;
  /// When false, only role/company + interests (name already shown above).
  final bool showName;

  @override
  Widget build(BuildContext context) {
    final work = poster.workLine;
    final interests = poster.topInterests.take(maxInterests).toList();
    final nameStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w800,
          height: 1.2,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showName)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: dense ? 14 : 16,
                backgroundColor: AppTheme.brandBlue.withValues(alpha: 0.12),
                child: Text(
                  poster.displayName.isNotEmpty ? poster.displayName[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: AppTheme.brandBlue,
                    fontWeight: FontWeight.w800,
                    fontSize: dense ? 12 : 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: poster.displayName, style: nameStyle),
                          if (poster.employeeVerified)
                            const WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: Icon(Icons.verified_rounded, size: 16, color: AppTheme.brandBlue),
                              ),
                            ),
                          if (roleBadge != null)
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.brandOrange.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    roleBadge!,
                                    style: const TextStyle(
                                      color: AppTheme.brandOrange,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (poster.employeeVerified)
                      Text(
                        'Verified employee',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.brandBlue,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    Text(
                      work ?? 'Role & company not set yet',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.inkMuted,
                            fontStyle: work == null ? FontStyle.italic : FontStyle.normal,
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          )
        else ...[
          if (roleBadge != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.brandOrange.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    roleBadge!,
                    style: const TextStyle(
                      color: AppTheme.brandOrange,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          Text(
            work ?? 'Role & company not set yet',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.inkMuted,
                  fontStyle: work == null ? FontStyle.italic : FontStyle.normal,
                  fontWeight: FontWeight.w600,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        if (interests.isNotEmpty) ...[
          SizedBox(height: dense ? 6 : 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: interests
                .map(
                  (t) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.brandBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      t,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.brandBlue,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}
