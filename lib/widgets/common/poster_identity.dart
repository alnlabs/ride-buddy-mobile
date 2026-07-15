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
  });

  final PosterCard poster;
  final String? roleBadge;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final work = poster.workLine;
    final interests = poster.topInterests.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: dense ? 14 : 16,
              backgroundColor: AppTheme.brandBlue.withOpacity(0.12),
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
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          poster.displayName,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (poster.employeeVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified_rounded, size: 16, color: AppTheme.brandBlue),
                      ],
                      if (roleBadge != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.brandOrange.withOpacity(0.14),
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
                      ],
                    ],
                  ),
                  if (poster.employeeVerified)
                    Text(
                      'Verified employee',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.brandBlue,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  if (work != null)
                    Text(
                      work,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted),
                      overflow: TextOverflow.ellipsis,
                    )
                  else
                    Text(
                      'Role & company not set yet',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.inkMuted,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                ],
              ),
            ),
          ],
        ),
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
                      color: AppTheme.brandBlue.withOpacity(0.08),
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
