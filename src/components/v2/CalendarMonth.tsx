import {
  addMonths,
  eachDayOfInterval,
  endOfMonth,
  endOfWeek,
  format,
  isSameDay,
  isSameMonth,
  startOfMonth,
  startOfWeek,
} from 'date-fns';
import { Pressable, StyleSheet, Text, View } from 'react-native';

import { colors, fonts } from '@/src/theme/colors';

type Marks = Record<string, { ride?: boolean; activity?: boolean }>;

export function CalendarMonth({
  month,
  selected,
  marks,
  onSelect,
  onMonthChange,
}: {
  month: Date;
  selected: Date;
  marks: Marks;
  onSelect: (day: Date) => void;
  onMonthChange: (month: Date) => void;
}) {
  const start = startOfWeek(startOfMonth(month), { weekStartsOn: 1 });
  const end = endOfWeek(endOfMonth(month), { weekStartsOn: 1 });
  const days = eachDayOfInterval({ start, end });

  return (
    <View>
      <View style={styles.nav}>
        <Pressable onPress={() => onMonthChange(addMonths(month, -1))}>
          <Text style={styles.navBtn}>Prev</Text>
        </Pressable>
        <Text style={styles.month}>{format(month, 'MMMM yyyy')}</Text>
        <Pressable onPress={() => onMonthChange(addMonths(month, 1))}>
          <Text style={styles.navBtn}>Next</Text>
        </Pressable>
      </View>
      <View style={styles.week}>
        {['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((d, i) => (
          <Text key={`${d}-${i}`} style={styles.dow}>
            {d}
          </Text>
        ))}
      </View>
      <View style={styles.grid}>
        {days.map((day) => {
          const key = format(day, 'yyyy-MM-dd');
          const mark = marks[key];
          const selectedDay = isSameDay(day, selected);
          const inMonth = isSameMonth(day, month);
          return (
            <Pressable key={key} onPress={() => onSelect(day)} style={styles.cell}>
              <View style={[styles.day, selectedDay && styles.dayOn]}>
                <Text
                  style={[
                    styles.dayText,
                    !inMonth && styles.out,
                    selectedDay && styles.dayTextOn,
                  ]}>
                  {format(day, 'd')}
                </Text>
              </View>
              <View style={styles.dots}>
                {mark?.ride ? <View style={[styles.mark, { backgroundColor: colors.brandBlue }]} /> : null}
                {mark?.activity ? <View style={[styles.mark, { backgroundColor: colors.brandOrange }]} /> : null}
              </View>
            </Pressable>
          );
        })}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  nav: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 },
  navBtn: { fontFamily: fonts.bodySemi, color: colors.brandBlue, fontSize: 14 },
  month: { fontFamily: fonts.displaySemi, fontSize: 18, color: colors.ink },
  week: { flexDirection: 'row' },
  dow: {
    width: `${100 / 7}%`,
    textAlign: 'center',
    fontFamily: fonts.bodySemi,
    fontSize: 12,
    color: colors.inkMuted,
    marginBottom: 8,
  },
  grid: { flexDirection: 'row', flexWrap: 'wrap' },
  cell: { width: `${100 / 7}%`, alignItems: 'center', paddingVertical: 4 },
  day: { width: 32, height: 32, borderRadius: 16, alignItems: 'center', justifyContent: 'center' },
  dayOn: { backgroundColor: colors.brandBlue },
  dayText: { fontFamily: fonts.bodySemi, color: colors.ink },
  dayTextOn: { color: '#fff' },
  out: { color: colors.line },
  dots: { flexDirection: 'row', gap: 3, height: 8, marginTop: 2 },
  mark: { width: 5, height: 5, borderRadius: 3 },
});
