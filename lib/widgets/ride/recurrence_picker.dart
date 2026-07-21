import 'package:flutter/material.dart';
import 'package:ridebuddy/theme/app_theme.dart';
import 'package:ridebuddy/widgets/common/ui_kit.dart';

enum RecurrenceFrequency {
  daily,
  weekdays,
  weekends,
  weekly,
  monthly,
  customDays,
}

extension RecurrenceFrequencyX on RecurrenceFrequency {
  String get apiValue => switch (this) {
        RecurrenceFrequency.daily => 'daily',
        RecurrenceFrequency.weekdays => 'weekdays',
        RecurrenceFrequency.weekends => 'weekends',
        RecurrenceFrequency.weekly => 'weekly',
        RecurrenceFrequency.monthly => 'monthly',
        RecurrenceFrequency.customDays => 'custom_days',
      };

  String get label => switch (this) {
        RecurrenceFrequency.daily => 'Daily',
        RecurrenceFrequency.weekdays => 'Weekdays',
        RecurrenceFrequency.weekends => 'Weekends',
        RecurrenceFrequency.weekly => 'Weekly',
        RecurrenceFrequency.monthly => 'Monthly',
        RecurrenceFrequency.customDays => 'Specific days',
      };
}

/// Shared one-day vs recurring controls for post ride / need.
class RecurrencePicker extends StatelessWidget {
  const RecurrencePicker({
    super.key,
    required this.recurring,
    required this.onRecurringChanged,
    required this.frequency,
    required this.onFrequencyChanged,
    required this.selectedDays,
    required this.onDaysChanged,
    required this.dayOfMonth,
    required this.onDayOfMonthChanged,
    required this.departTime,
    required this.onDepartTimePressed,
  });

  final bool recurring;
  final ValueChanged<bool> onRecurringChanged;
  final RecurrenceFrequency frequency;
  final ValueChanged<RecurrenceFrequency> onFrequencyChanged;
  final Set<int> selectedDays;
  final ValueChanged<Set<int>> onDaysChanged;
  final int dayOfMonth;
  final ValueChanged<int> onDayOfMonthChanged;
  final TimeOfDay departTime;
  final VoidCallback onDepartTimePressed;

  static const _dayLabels = {
    1: 'Mon',
    2: 'Tue',
    3: 'Wed',
    4: 'Thu',
    5: 'Fri',
    6: 'Sat',
    7: 'Sun',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SoftPanel(
          padding: const EdgeInsets.all(6),
          child: Row(
            children: [
              Expanded(
                child: _ModeChip(
                  label: 'One day',
                  selected: !recurring,
                  onTap: () => onRecurringChanged(false),
                ),
              ),
              Expanded(
                child: _ModeChip(
                  label: 'Recurring',
                  selected: recurring,
                  onTap: () => onRecurringChanged(true),
                ),
              ),
            ],
          ),
        ),
        if (recurring) ...[
          const SizedBox(height: 12),
          Text(
            'Creates today’s post when it matches — past departures leave the live list.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: RecurrenceFrequency.values.map((f) {
              return ChoiceChip(
                label: Text(f.label),
                selected: frequency == f,
                onSelected: (_) => onFrequencyChanged(f),
              );
            }).toList(),
          ),
          if (frequency == RecurrenceFrequency.weekly ||
              frequency == RecurrenceFrequency.customDays) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _dayLabels.entries.map((e) {
                final selected = selectedDays.contains(e.key);
                return FilterChip(
                  label: Text(e.value),
                  selected: selected,
                  onSelected: (v) {
                    final next = {...selectedDays};
                    if (v) {
                      next.add(e.key);
                    } else {
                      next.remove(e.key);
                    }
                    onDaysChanged(next);
                  },
                );
              }).toList(),
            ),
          ],
          if (frequency == RecurrenceFrequency.monthly) ...[
            const SizedBox(height: 12),
            SoftPanel(
              child: Row(
                children: [
                  const Expanded(child: Text('Day of month')),
                  DropdownButton<int>(
                    value: dayOfMonth.clamp(1, 31),
                    items: [
                      for (var d = 1; d <= 31; d++)
                        DropdownMenuItem(value: d, child: Text('$d')),
                    ],
                    onChanged: (v) {
                      if (v != null) onDayOfMonthChanged(v);
                    },
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          SoftPanel(
            onTap: onDepartTimePressed,
            child: Row(
              children: [
                const Icon(Icons.schedule_rounded, color: AppTheme.brandBlue),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Depart time', style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 2),
                      Text(
                        departTime.format(context),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppTheme.inkMuted),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppTheme.brandBlue.withOpacity(0.12) : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: selected ? AppTheme.brandBlue : AppTheme.inkMuted,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
          ),
        ),
      ),
    );
  }
}
