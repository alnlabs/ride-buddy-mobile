import { router, useFocusEffect } from 'expo-router';
import { useCallback, useMemo, useState } from 'react';
import { Alert, Platform, Pressable, RefreshControl, ScrollView, Text, View } from 'react-native';

import { ErrorBanner, PrimaryButton } from '@/src/components/ui/kit';
import { ScreenScaffold } from '@/src/components/v2/primitives';
import { RideSchedule, frequencyLabel } from '@/src/models/types';
import { rideRepo } from '@/src/services/rideRepository';
import { messageFrom, useAuth } from '@/src/store/auth';
import { colors, fonts, weights } from '@/src/theme/colors';

const DAY_NAMES = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

export default function SchedulesScreen() {
  const { userId } = useAuth();
  const [list, setList] = useState<RideSchedule[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      setList(uniqueSchedules(await rideRepo.mySchedules()));
      setError(null);
    } catch (e) {
      setError(messageFrom(e));
    } finally {
      setLoading(false);
    }
  }, []);

  useFocusEffect(
    useCallback(() => {
      void load();
    }, [load, userId]),
  );

  const schedules = useMemo(() => uniqueSchedules(list), [list]);
  const goCreate = () => router.push({ pathname: '/ride/post', params: { recurring: '1' } });
  const empty = schedules.length === 0 && !error && !loading;

  return (
    <ScreenScaffold>
      <ScrollView
        contentContainerStyle={content}
        keyboardShouldPersistTaps="handled"
        refreshControl={
          Platform.OS === 'web' ? undefined : <RefreshControl refreshing={loading} onRefresh={load} />
        }>
        <Text style={title}>My schedules</Text>
        {empty ? (
          <View style={{ marginTop: 12 }}>
            <Text style={emptyTitle}>You don’t have any recurring commutes yet.</Text>
            <Text style={intro}>Create a commute that automatically posts according to your schedule.</Text>
            <View style={{ marginTop: 16 }}>
              <PrimaryButton label="Create commute" icon="add" onPress={goCreate} />
            </View>
          </View>
        ) : (
          <>
            <Text style={intro}>These commutes post themselves.{'\n'}Pause a week, or stop one for good.</Text>
            {error ? (
              <View style={{ marginTop: 8, marginBottom: 8 }}>
                <ErrorBanner message={error} />
              </View>
            ) : null}
            {schedules.map((schedule) => (
              <ScheduleCard key={schedule.id} schedule={schedule} onChanged={load} />
            ))}
            {schedules.length > 0 ? (
              <View style={{ marginTop: 4 }}>
                <PrimaryButton label="Add another commute" icon="add" onPress={goCreate} />
              </View>
            ) : null}
          </>
        )}
      </ScrollView>
    </ScreenScaffold>
  );
}

function ScheduleCard({
  schedule,
  onChanged,
}: Readonly<{
  schedule: RideSchedule;
  onChanged: () => Promise<void>;
}>) {
  const hosting = schedule.kind === 'ride';
  const live = schedule.active;

  const toggle = async () => {
    if (schedule.active) await rideRepo.pauseSchedule(schedule.id);
    else await rideRepo.resumeSchedule(schedule.id);
    await onChanged();
  };

  const stop = () => {
    Alert.alert('Stop this commute?', 'It will not post again. Past rides stay as they are.', [
      { text: 'Keep' },
      {
        text: 'Stop',
        style: 'destructive',
        onPress: async () => {
          await rideRepo.cancelSchedule(schedule.id);
          await onChanged();
        },
      },
    ]);
  };

  return (
    <View style={card}>
      <View style={cardTop}>
        <Text style={[kind, { color: hosting ? colors.brandBlue : colors.brandOrange }]}>
          {hosting ? 'Offering seats' : 'Need a seat'}
        </Text>
        <Text style={[liveDot, { color: live ? colors.success : colors.inkMuted }]}>
          {live ? '● Live' : '○ Paused'}
        </Text>
      </View>
      <Text style={place}>{schedule.originLabel}</Text>
      <Text style={arrow}>→</Text>
      <Text style={place}>{schedule.destinationLabel}</Text>
      <Text style={meta}>{rhythmLine(schedule)}</Text>
      <View style={actions}>
        <Pressable onPress={toggle} hitSlop={8} style={actionHit}>
          <Text style={pauseLabel}>{schedule.active ? 'Pause' : 'Resume'}</Text>
        </Pressable>
        <Pressable onPress={stop} hitSlop={8} style={actionHit}>
          <Text style={stopLabel}>Stop</Text>
        </Pressable>
      </View>
    </View>
  );
}

function uniqueSchedules(items: RideSchedule[]) {
  const seen = new Set<string>();
  return items.filter((item) => {
    const key = item.id || fingerprint(item);
    if (!key || seen.has(key)) return false;
    seen.add(key);
    return true;
  });
}

function fingerprint(item: RideSchedule) {
  return [item.kind, item.originLabel, item.destinationLabel, item.departLocalTime, item.frequency, item.daysOfWeek.join('-')].join('|');
}

function rhythmLine(schedule: RideSchedule) {
  const time = formatClock(schedule.departLocalTime);
  const freq = frequencyLabel(schedule.frequency);
  const days = daysLine(schedule);
  return days ? `${freq} · ${days} · ${time}` : `${freq} · ${time}`;
}

function formatClock(raw: string) {
  const [h, m] = raw.split(':').map(Number);
  if (!Number.isFinite(h) || !Number.isFinite(m)) return raw.slice(0, 5);
  const hour = h % 12 || 12;
  return `${hour}:${String(m).padStart(2, '0')} ${h >= 12 ? 'PM' : 'AM'}`;
}

function daysLine(schedule: RideSchedule) {
  if (schedule.frequency === 'monthly' && schedule.dayOfMonth) return `Day ${schedule.dayOfMonth}`;
  if (schedule.frequency === 'weekdays') return 'Mon–Fri';
  if (schedule.frequency === 'weekends') return 'Sat–Sun';
  if (!schedule.daysOfWeek.length) return '';
  return schedule.daysOfWeek
    .slice()
    .sort((a, b) => a - b)
    .map((d) => DAY_NAMES[d % 7] ?? '')
    .filter(Boolean)
    .join(', ');
}

const content = {
  paddingHorizontal: 20,
  paddingTop: 8,
  paddingBottom: 32,
} as const;
const title = {
  fontFamily: fonts.display,
  fontWeight: weights.display,
  fontSize: 28,
  color: colors.ink,
} as const;
const intro = {
  fontFamily: fonts.body,
  fontWeight: weights.body,
  fontSize: 15,
  lineHeight: 22,
  color: colors.inkMuted,
  marginTop: 8,
  marginBottom: 16,
} as const;
const emptyTitle = {
  fontFamily: fonts.bodySemi,
  fontWeight: weights.bodySemi,
  fontSize: 16,
  color: colors.ink,
} as const;
const card = {
  backgroundColor: colors.surfaceElevated,
  borderWidth: 1,
  borderColor: colors.line,
  borderRadius: 16,
  paddingHorizontal: 16,
  paddingVertical: 16,
  marginBottom: 12,
} as const;
const cardTop = {
  flexDirection: 'row' as const,
  alignItems: 'center' as const,
  justifyContent: 'space-between' as const,
};
const kind = {
  fontFamily: fonts.bodySemi,
  fontWeight: weights.bodySemi,
  fontSize: 14,
} as const;
const liveDot = {
  fontFamily: fonts.bodySemi,
  fontWeight: weights.bodySemi,
  fontSize: 13,
} as const;
const place = {
  fontFamily: fonts.displaySemi,
  fontWeight: weights.displaySemi,
  fontSize: 17,
  lineHeight: 24,
  color: colors.ink,
  marginTop: 6,
} as const;
const arrow = {
  fontFamily: fonts.body,
  fontWeight: weights.body,
  fontSize: 16,
  color: colors.inkMuted,
  marginTop: 2,
} as const;
const meta = {
  fontFamily: fonts.body,
  fontWeight: weights.body,
  fontSize: 14,
  lineHeight: 20,
  color: colors.inkMuted,
  marginTop: 10,
} as const;
const actions = {
  flexDirection: 'row' as const,
  justifyContent: 'space-between' as const,
  alignItems: 'center' as const,
  marginTop: 12,
};
const actionHit = { minHeight: 44, justifyContent: 'center' as const };
const pauseLabel = {
  fontFamily: fonts.bodySemi,
  fontWeight: weights.bodySemi,
  fontSize: 15,
  color: colors.brandBlue,
} as const;
const stopLabel = {
  fontFamily: fonts.bodySemi,
  fontWeight: weights.bodySemi,
  fontSize: 15,
  color: colors.danger,
} as const;
