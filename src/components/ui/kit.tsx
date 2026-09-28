import { MaterialIcons } from '@expo/vector-icons';
import { LinearGradient } from 'expo-linear-gradient';
import { ReactNode } from 'react';
import {
  ActivityIndicator,
  Image,
  Pressable,
  StyleSheet,
  Text,
  TextInput,
  TextInputProps,
  View,
  ViewStyle,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { colors, fonts, weights } from '@/src/theme/colors';

export function SkyScaffold({
  children,
  padded,
}: {
  children: ReactNode;
  padded?: boolean;
}) {
  return (
    <LinearGradient colors={[colors.skyTop, colors.skyMid, colors.surface]} locations={[0, 0.35, 1]} style={styles.flex}>
      <SafeAreaView style={[styles.flex, padded && styles.pad]} edges={['top']}>
        {children}
      </SafeAreaView>
    </LinearGradient>
  );
}

export function BrandWordmark({ fontSize = 34, center }: { fontSize?: number; center?: boolean }) {
  return (
    <Text style={{ textAlign: center ? 'center' : 'left' }}>
      <Text style={{ fontFamily: fonts.displayExtra, fontWeight: weights.displayExtra, fontSize, color: colors.brandBlue }}>Ride</Text>
      <Text style={{ fontFamily: fonts.displayExtra, fontWeight: weights.displayExtra, fontSize, color: colors.brandOrange }}>Buddy</Text>
    </Text>
  );
}

export function ScreenTitle({ children }: { children: string }) {
  return <Text style={styles.headline}>{children}</Text>;
}

export function Muted({ children, center }: { children: ReactNode; center?: boolean }) {
  return <Text style={[styles.muted, center && { textAlign: 'center' }]}>{children}</Text>;
}

export function SectionLabel({ children }: { children: string }) {
  return <Text style={styles.section}>{children.toUpperCase()}</Text>;
}

export function PrimaryButton({
  label,
  onPress,
  loading,
  icon,
  color = colors.brandBlue,
  disabled,
}: {
  label: string;
  onPress?: () => void;
  loading?: boolean;
  icon?: keyof typeof MaterialIcons.glyphMap;
  color?: string;
  disabled?: boolean;
}) {
  return (
    <Pressable
      onPress={loading || disabled ? undefined : onPress}
      style={[styles.btn, { backgroundColor: color, opacity: loading || disabled ? 0.6 : 1 }]}>
      {loading ? (
        <ActivityIndicator color="#fff" />
      ) : (
        <View style={styles.rowCenter}>
          {icon ? <MaterialIcons name={icon} size={20} color="#fff" /> : null}
          <Text style={styles.btnLabel}>{label}</Text>
        </View>
      )}
    </Pressable>
  );
}

export function OutlineButton({ label, onPress, danger }: { label: string; onPress?: () => void; danger?: boolean }) {
  const color = danger ? colors.danger : colors.brandBlue;
  return (
    <Pressable onPress={onPress} style={[styles.outline, { borderColor: color }]}>
      <Text style={[styles.outlineLabel, { color }]}>{label}</Text>
    </Pressable>
  );
}

export function SoftPanel({
  children,
  onPress,
  style,
  padding = 16,
}: {
  children: ReactNode;
  onPress?: () => void;
  style?: ViewStyle;
  padding?: number;
}) {
  const inner = (
    <View style={[styles.panel, { padding }, style]}>{children}</View>
  );
  if (!onPress) return inner;
  return (
    <Pressable onPress={onPress} style={style}>
      <View style={[styles.panel, { padding }]}>{children}</View>
    </Pressable>
  );
}

export function ActionRow({
  icon,
  title,
  subtitle,
  onPress,
  accent = colors.brandBlue,
  badgeCount,
}: {
  icon: keyof typeof MaterialIcons.glyphMap;
  title: string;
  subtitle?: string;
  onPress: () => void;
  accent?: string;
  badgeCount?: number;
}) {
  const badge = badgeCount ?? 0;
  return (
    <Pressable onPress={onPress} style={styles.action}>
      <View style={[styles.iconBox, { backgroundColor: `${accent}1F` }]}>
        <MaterialIcons name={icon} size={22} color={accent} />
      </View>
      <View style={styles.flex}>
        <Text style={styles.title}>{title}</Text>
        {subtitle ? <Text style={styles.small}>{subtitle}</Text> : null}
      </View>
      {badge > 0 ? (
        <View style={[styles.badge, { backgroundColor: accent }]}>
          <Text style={styles.badgeText}>{badge > 99 ? '99+' : badge}</Text>
        </View>
      ) : null}
      <MaterialIcons name="chevron-right" size={20} color={colors.inkMuted} />
    </Pressable>
  );
}

export function StrengthBar({ value }: { value: number }) {
  const v = Math.min(1, Math.max(0, value / 100));
  return (
    <View>
      <View style={styles.spaceBetween}>
        <Text style={styles.titleSmall}>Profile strength</Text>
        <Text style={[styles.titleSmall, { color: colors.brandBlue }]}>{value}%</Text>
      </View>
      <View style={styles.track}>
        <View
          style={[
            styles.fill,
            { width: `${v * 100}%`, backgroundColor: value >= 70 ? colors.success : colors.brandOrange },
          ]}
        />
      </View>
    </View>
  );
}

export function ErrorBanner({ message }: { message: string }) {
  return (
    <View style={styles.errorBox}>
      <Text style={styles.errorText}>{message}</Text>
    </View>
  );
}

export function EmptyState({
  title,
  subtitle,
  icon = 'inbox',
  actionLabel,
  onAction,
}: {
  title: string;
  subtitle?: string;
  icon?: keyof typeof MaterialIcons.glyphMap;
  actionLabel?: string;
  onAction?: () => void;
}) {
  return (
    <View style={{ alignItems: 'center', gap: 8, paddingVertical: 8 }}>
      <MaterialIcons name={icon} size={36} color={colors.brandBlue} />
      <Text style={styles.title}>{title}</Text>
      {subtitle ? <Muted center>{subtitle}</Muted> : null}
      {actionLabel ? <PrimaryButton label={actionLabel} onPress={onAction} /> : null}
    </View>
  );
}

export function ErrorView({ message, onRetry }: { message: string; onRetry?: () => void }) {
  return (
    <View style={{ padding: 20 }}>
      <SoftPanel>
        <EmptyState title="Something went wrong" subtitle={message} actionLabel="Retry" onAction={onRetry} icon="error-outline" />
      </SoftPanel>
    </View>
  );
}

export function LoadingSkeleton() {
  return (
    <View style={{ padding: 20, gap: 12 }}>
      <ActivityIndicator color={colors.brandBlue} />
    </View>
  );
}

export function FareChip({ pricePerSeat, compact }: { pricePerSeat: number; compact?: boolean }) {
  const amount = Math.round(pricePerSeat);
  if (compact) {
    return <Text style={styles.fareCompact}>₹{amount} / seat · share cost</Text>;
  }
  return (
    <View style={styles.fareBox}>
      <MaterialIcons name="payments" size={22} color={colors.brandOrange} />
      <View style={styles.flex}>
        <Text style={styles.fareTitle}>₹{amount} per seat</Text>
        <Text style={styles.small}>Share the trip cost · cash to the host</Text>
      </View>
    </View>
  );
}

export function Field(props: TextInputProps & { label?: string }) {
  const { label, style, ...rest } = props;
  return (
    <View style={{ gap: 6 }}>
      {label ? <Text style={styles.label}>{label}</Text> : null}
      <TextInput
        placeholderTextColor={colors.inkMuted}
        style={[styles.input, style]}
        {...rest}
      />
    </View>
  );
}

export function Avatar({ name, size = 48, uri }: { name?: string | null; size?: number; uri?: string | null }) {
  const letter = name?.trim()?.[0]?.toUpperCase() ?? 'R';
  return (
    <View
      style={{
        width: size,
        height: size,
        borderRadius: size / 2,
        backgroundColor: `${colors.brandBlue}1F`,
        alignItems: 'center',
        justifyContent: 'center',
        overflow: 'hidden',
      }}>
      {uri ? (
        <Image source={{ uri }} style={{ width: size, height: size }} resizeMode="cover" />
      ) : (
        <Text style={{ color: colors.brandBlue, fontFamily: fonts.bodyBold, fontWeight: weights.bodyBold, fontSize: size * 0.4 }}>
          {letter}
        </Text>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  flex: { flex: 1 },
  pad: { paddingHorizontal: 20 },
  headline: { fontFamily: fonts.display, fontWeight: weights.display, fontSize: 28, color: colors.ink },
  muted: { fontFamily: fonts.body, fontWeight: weights.body, fontSize: 16, color: colors.inkMuted, lineHeight: 22 },
  section: { fontFamily: fonts.bodySemi, fontWeight: weights.bodySemi, fontSize: 11, color: colors.inkMuted },
  btn: { height: 52, borderRadius: 14, alignItems: 'center', justifyContent: 'center', paddingHorizontal: 20 },
  btnLabel: { color: '#fff', fontFamily: fonts.bodyBold, fontWeight: weights.bodyBold, fontSize: 16, marginLeft: 8 },
  rowCenter: { flexDirection: 'row', alignItems: 'center' },
  outline: { height: 52, borderRadius: 14, borderWidth: 1.4, alignItems: 'center', justifyContent: 'center' },
  outlineLabel: { fontFamily: fonts.bodyBold, fontWeight: weights.bodyBold, fontSize: 16 },
  panel: { backgroundColor: colors.surfaceElevated, borderRadius: 16, borderWidth: 1, borderColor: colors.line },
  action: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 14,
    backgroundColor: colors.surfaceElevated,
    borderRadius: 16,
    paddingHorizontal: 14,
    paddingVertical: 14,
  },
  iconBox: { width: 44, height: 44, borderRadius: 12, alignItems: 'center', justifyContent: 'center' },
  title: { fontFamily: fonts.displaySemi, fontWeight: weights.displaySemi, fontSize: 16, color: colors.ink },
  titleSmall: { fontFamily: fonts.bodySemi, fontWeight: weights.bodySemi, fontSize: 14, color: colors.ink },
  small: { fontFamily: fonts.body, fontWeight: weights.body, fontSize: 13, color: colors.inkMuted, marginTop: 2 },
  badge: { minWidth: 22, borderRadius: 999, paddingHorizontal: 7, paddingVertical: 3 },
  badgeText: { color: '#fff', fontFamily: fonts.bodyBold, fontWeight: weights.bodyBold, fontSize: 12, textAlign: 'center' },
  spaceBetween: { flexDirection: 'row', justifyContent: 'space-between' },
  track: { height: 8, backgroundColor: colors.line, borderRadius: 6, overflow: 'hidden', marginTop: 8 },
  fill: { height: 8, borderRadius: 6 },
  errorBox: {
    padding: 12,
    borderRadius: 12,
    backgroundColor: `${colors.danger}14`,
    borderWidth: 1,
    borderColor: `${colors.danger}40`,
  },
  errorText: { color: colors.danger, fontFamily: fonts.bodySemi, fontWeight: weights.bodySemi },
  fareCompact: { fontFamily: fonts.bodyBold, fontWeight: weights.bodyBold, color: colors.brandOrange, fontSize: 13 },
  fareBox: {
    flexDirection: 'row',
    gap: 10,
    padding: 12,
    borderRadius: 14,
    backgroundColor: `${colors.brandOrange}1A`,
    borderWidth: 1,
    borderColor: `${colors.brandOrange}59`,
    alignItems: 'center',
  },
  fareTitle: { fontFamily: fonts.displayExtra, fontWeight: weights.displayExtra, color: colors.brandOrange, fontSize: 16 },
  input: {
    backgroundColor: colors.surfaceElevated,
    borderWidth: 1,
    borderColor: colors.line,
    borderRadius: 14,
    paddingHorizontal: 16,
    paddingVertical: 14,
    fontFamily: fonts.body,
    fontWeight: weights.body,
    fontSize: 16,
    color: colors.ink,
  },
  label: { fontFamily: fonts.bodySemi, fontWeight: weights.bodySemi, color: colors.inkMuted, fontSize: 13 },
});
