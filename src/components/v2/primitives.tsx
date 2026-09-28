import { MaterialIcons } from '@expo/vector-icons';
import { ReactNode } from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { matchLabel } from '@/src/lib/commute';
import { colors, fonts, weights } from '@/src/theme/colors';

export function ScreenScaffold({
  children,
  tone = 'paper',
}: {
  children: ReactNode;
  tone?: 'paper' | 'map' | 'ink';
}) {
  const bg = tone === 'map' ? colors.skyMid : tone === 'ink' ? colors.ink : colors.surface;
  return (
    <SafeAreaView style={[styles.flex, { backgroundColor: bg }]} edges={['top']}>
      {children}
    </SafeAreaView>
  );
}

export function SegmentedControl({
  value,
  options,
  onChange,
}: {
  value: string;
  options: { id: string; label: string }[];
  onChange: (id: string) => void;
}) {
  return (
    <View style={styles.segment}>
      {options.map((option) => {
        const active = option.id === value;
        return (
          <Pressable
            key={option.id}
            onPress={() => onChange(option.id)}
            style={[styles.segmentItem, active && styles.segmentActive]}>
            <Text style={[styles.segmentLabel, active && styles.segmentLabelActive]}>{option.label}</Text>
          </Pressable>
        );
      })}
    </View>
  );
}

export function MatchBadge({ percent }: { percent: number }) {
  const good = percent >= 80;
  const color = good ? colors.matchGood : percent >= 65 ? colors.matchFair : colors.inkMuted;
  return (
    <Text style={{ fontFamily: fonts.bodySemi, fontWeight: weights.bodySemi, color, fontSize: 13 }}>
      {good ? '●' : '○'} {percent}% · {matchLabel(percent)}
    </Text>
  );
}

export function HostTrust({
  name,
  verified,
  rides,
}: {
  name: string;
  verified?: boolean;
  rides?: number;
}) {
  return (
    <View style={styles.hostRow}>
      <View style={styles.avatar}>
        <Text style={styles.avatarText}>{name.trim()[0]?.toUpperCase() ?? 'R'}</Text>
      </View>
      <View style={styles.flex}>
        <View style={styles.row}>
          <Text style={styles.hostName}>{name}</Text>
          {verified ? <MaterialIcons name="verified" size={16} color={colors.brandBlue} /> : null}
        </View>
        <Text style={styles.hostMeta}>
          {rides != null ? `${rides} completed rides` : 'Ride Host'}
          {verified ? '  ·  Workplace verified' : ''}
        </Text>
        <Text style={styles.experience}>Good ride experience</Text>
      </View>
    </View>
  );
}

export function GroupLabel({ children }: { children: string }) {
  return <Text style={styles.group}>{children}</Text>;
}

export function HubRow({
  title,
  onPress,
  accent = colors.brandBlue,
}: {
  title: string;
  onPress: () => void;
  accent?: string;
}) {
  return (
    <Pressable onPress={onPress} style={styles.hubRow}>
      <View style={[styles.dot, { backgroundColor: accent }]} />
      <Text style={styles.hubTitle}>{title}</Text>
      <MaterialIcons name="chevron-right" size={20} color={colors.inkMuted} />
    </Pressable>
  );
}

export function FilterChip({
  label,
  active,
  onPress,
}: {
  label: string;
  active?: boolean;
  onPress?: () => void;
}) {
  return (
    <Pressable onPress={onPress} style={[styles.chip, active && styles.chipOn]}>
      <Text style={[styles.chipText, active && styles.chipTextOn]}>{label}</Text>
    </Pressable>
  );
}

export function StepDots({ step, total }: { step: number; total: number }) {
  return (
    <View style={styles.dots}>
      {Array.from({ length: total }, (_, i) => (
        <View key={i} style={[styles.dotBar, i === step && styles.dotBarOn, i < step && styles.dotBarDone]} />
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  flex: { flex: 1 },
  segment: {
    flexDirection: 'row',
    backgroundColor: colors.skyMid,
    borderRadius: 14,
    padding: 4,
  },
  segmentItem: { flex: 1, height: 36, borderRadius: 11, alignItems: 'center', justifyContent: 'center' },
  segmentActive: { backgroundColor: colors.surfaceElevated },
  segmentLabel: { fontFamily: fonts.bodySemi, fontWeight: weights.bodySemi, fontSize: 13, color: colors.inkMuted },
  segmentLabelActive: { color: colors.ink },
  hostRow: { flexDirection: 'row', gap: 12, alignItems: 'center' },
  avatar: {
    width: 52,
    height: 52,
    borderRadius: 26,
    backgroundColor: `${colors.brandBlue}1A`,
    alignItems: 'center',
    justifyContent: 'center',
  },
  avatarText: { fontFamily: fonts.display, fontWeight: weights.display, color: colors.brandBlue, fontSize: 20 },
  row: { flexDirection: 'row', alignItems: 'center', gap: 6 },
  hostName: { fontFamily: fonts.displaySemi, fontWeight: weights.displaySemi, fontSize: 18, color: colors.ink },
  hostMeta: { fontFamily: fonts.body, fontWeight: weights.body, fontSize: 13, color: colors.inkMuted, marginTop: 2 },
  experience: { fontFamily: fonts.bodySemi, fontWeight: weights.bodySemi, fontSize: 13, color: colors.matchGood, marginTop: 2 },
  group: {
    fontFamily: fonts.bodySemi,
    fontWeight: weights.bodySemi,
    fontSize: 11,
    color: colors.inkMuted,
    marginBottom: 8,
  },
  hubRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 14,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: colors.line,
    gap: 12,
  },
  dot: { width: 8, height: 8, borderRadius: 4 },
  hubTitle: { flex: 1, fontFamily: fonts.bodySemi, fontWeight: weights.bodySemi, fontSize: 16, color: colors.ink },
  chip: {
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 999,
    backgroundColor: colors.skyMid,
  },
  chipOn: { backgroundColor: `${colors.brandBlue}1A` },
  chipText: { fontFamily: fonts.bodySemi, fontWeight: weights.bodySemi, fontSize: 13, color: colors.inkMuted },
  chipTextOn: { color: colors.brandBlue },
  dots: { flexDirection: 'row', gap: 6 },
  dotBar: { flex: 1, height: 4, borderRadius: 4, backgroundColor: colors.line },
  dotBarOn: { backgroundColor: colors.brandBlue },
  dotBarDone: { backgroundColor: `${colors.brandBlue}66` },
});
