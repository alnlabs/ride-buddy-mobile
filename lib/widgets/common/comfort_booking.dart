import 'package:flutter/material.dart';
import 'package:ridebuddy/theme/app_theme.dart';

/// When the co-rider preferred comfort but the ride is compact/standard,
/// ask before booking instead of blocking.
Future<bool> confirmCompactBookingIfNeeded(
  BuildContext context, {
  required bool preferComfort,
  required bool rideIsComfort,
}) async {
  if (!preferComfort || rideIsComfort) return true;

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Compact seat vehicle'),
      content: const Text(
        'You preferred comfort (max 2 in the back), but this ride is a compact / standard vehicle. '
        'Are you OK to book it?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Not now'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppTheme.brandBlue),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Yes, book compact'),
        ),
      ],
    ),
  );
  return ok == true;
}
