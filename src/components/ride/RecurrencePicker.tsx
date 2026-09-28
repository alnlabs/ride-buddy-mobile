import { Pressable, StyleSheet, Switch, Text, View } from 'react-native';

import { SoftPanel } from '@/src/components/ui/kit';
import { colors, fonts } from '@/src/theme/colors';

export type RecurrenceFrequency = 'daily' | 'weekdays' | 'weekends' | 'weekly' | 'monthly' | 'custom_days';

const FREQS: { value: RecurrenceFrequency; label: string }[] = [
  { value: 'daily', label: 'Daily' },
  { value: 'weekdays', label: 'Weekdays' },
  { value: 'weekends', label: 'Weekends' },
  { value: 'weekly', label: 'Weekly' },
  { value: 'monthly', label: 'Monthly' },
  { value: 'custom_days', label: 'Specific days' },
];

const DAYS = [
  { n: 1, l: 'Mon' },
  { n: 2, l: 'Tue' },
  { n: 3, l: 'Wed' },
  { n: 4, l: 'Thu' },
  { n: 5, l: 'Fri' },
  { n: 6, l: 'Sat' },
  { n: 7, l: 'Sun' },
];

type Props = {
  recurring: boolean;
  onRecurringChanged: (v: boolean) => void;
  frequency: RecurrenceFrequency;
  onFrequencyChanged: (f: RecurrenceFrequency) => void;
  selectedDays: number[];
  onDaysChanged: (d: number[]) => void;
  dayOfMonth: number;
  onDayOfMonthChanged: (d: number) => void;
  departTimeLabel: string;
  onDepartTimePressed: () => void;
};

export function RecurrencePicker({
  recurring,
  onRecurringChanged,
  frequency,
  onFrequencyChanged,
  selectedDays,
  onDaysChanged,
  dayOfMonth,
  onDayOfMonthChanged,
  departTimeLabel,
  onDepartTimePressed,
}: Props) {
  return (
    <View style={{ gap: 10 }}>
      <SoftPanel padding={6}>
        <View style={styles.toggleRow}>
          <Pressable onPress={() => onRecurringChanged(false)} style={[styles.seg, !recurring && styles.segOn]}>
            <Text style={[styles.segText, !recurring && styles.segTextOn]}>One trip</Text>
          </Pressable>
          <Pressable onPress={() => onRecurringChanged(true)} style={[styles.seg, recurring && styles.segOn]}>
            <Text style={[styles.segText, recurring && styles.segTextOn]}>Recurring</Text>
          </Pressable>
        </View>
      </SoftPanel>
      {recurring ? (
        <SoftPanel>
          <Text style={styles.label}>How often</Text>
          <View style={styles.wrap}>
            {FREQS.map((f) => (
              <Pressable
                key={f.value}
                onPress={() => onFrequencyChanged(f.value)}
                style={[styles.chip, frequency === f.value && styles.chipOn]}>
                <Text style={[styles.chipText, frequency === f.value && styles.chipTextOn]}>{f.label}</Text>
              </Pressable>
            ))}
          </View>
          {(frequency === 'weekly' || frequency === 'custom_days') && (
            <View style={[styles.wrap, { marginTop: 10 }]}>
              {DAYS.map((d) => {
                const on = selectedDays.includes(d.n);
                return (
                  <Pressable
                    key={d.n}
                    onPress={() =>
                      onDaysChanged(on ? selectedDays.filter((x) => x !== d.n) : [...selectedDays, d.n].sort())
                    }
                    style={[styles.chip, on && styles.chipOn]}>
                    <Text style={[styles.chipText, on && styles.chipTextOn]}>{d.l}</Text>
                  </Pressable>
                );
              })}
            </View>
          )}
          {frequency === 'monthly' && (
            <View style={{ marginTop: 10, flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' }}>
              <Text style={styles.label}>Day of month</Text>
              <View style={{ flexDirection: 'row', gap: 12 }}>
                <Pressable onPress={() => onDayOfMonthChanged(Math.max(1, dayOfMonth - 1))}>
                  <Text style={styles.link}>−</Text>
                </Pressable>
                <Text style={styles.value}>{dayOfMonth}</Text>
                <Pressable onPress={() => onDayOfMonthChanged(Math.min(28, dayOfMonth + 1))}>
                  <Text style={styles.link}>+</Text>
                </Pressable>
              </View>
            </View>
          )}
          <Pressable onPress={onDepartTimePressed} style={{ marginTop: 12 }}>
            <Text style={styles.label}>Depart time</Text>
            <Text style={styles.value}>{departTimeLabel}</Text>
          </Pressable>
          <View style={{ flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', marginTop: 8 }}>
            <Text style={styles.label}>Timezone</Text>
            <Text style={styles.sub}>Asia/Kolkata</Text>
          </View>
        </SoftPanel>
      ) : null}
    </View>
  );
}

void Switch;

const styles = StyleSheet.create({
  toggleRow: { flexDirection: 'row' },
  seg: { flex: 1, paddingVertical: 12, alignItems: 'center', borderRadius: 12 },
  segOn: { backgroundColor: `${colors.brandBlue}14` },
  segText: { fontFamily: fonts.bodySemi, color: colors.inkMuted },
  segTextOn: { color: colors.brandBlue, fontFamily: fonts.bodyBold },
  label: { fontFamily: fonts.bodySemi, color: colors.inkMuted, marginBottom: 8 },
  wrap: { flexDirection: 'row', flexWrap: 'wrap', gap: 8 },
  chip: { borderWidth: 1, borderColor: colors.line, borderRadius: 10, paddingHorizontal: 10, paddingVertical: 6 },
  chipOn: { backgroundColor: `${colors.brandOrange}2E`, borderColor: colors.brandOrange },
  chipText: { fontFamily: fonts.bodySemi, color: colors.ink },
  chipTextOn: { color: colors.brandOrange },
  value: { fontFamily: fonts.displaySemi, color: colors.ink, fontSize: 16 },
  link: { color: colors.brandBlue, fontFamily: fonts.bodyBold, fontSize: 20 },
  sub: { fontFamily: fonts.body, color: colors.inkMuted },
});
