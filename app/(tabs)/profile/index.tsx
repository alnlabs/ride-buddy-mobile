import { MaterialIcons } from '@expo/vector-icons';
import { useFocusEffect, router } from 'expo-router';
import { useCallback, useState } from 'react';
import { Pressable, ScrollView, Text, View } from 'react-native';

import { Avatar, ErrorView, LoadingSkeleton } from '@/src/components/ui/kit';
import { ScreenScaffold } from '@/src/components/v2/primitives';
import { profileCompletion } from '@/src/lib/commute';
import { Ride, RideSchedule, SavedPlace, vehicleDisplayName } from '@/src/models/types';
import { rideRepo } from '@/src/services/rideRepository';
import { useAuth } from '@/src/store/auth';
import { useChatInbox, useMyTrips, useProfile, useVehicles } from '@/src/store/query';
import { colors, fonts, weights } from '@/src/theme/colors';

const SHARED = new Set(['accepted', 'completed']);

export default function ProfileHub() {
  const { phone, logout, displayName } = useAuth();
  const profile = useProfile();
  const trips = useMyTrips();
  const vehicles = useVehicles();
  const inbox = useChatInbox();
  const [places, setPlaces] = useState<SavedPlace[] | null>(null);
  const [schedules, setSchedules] = useState<RideSchedule[]>([]);
  const [offered, setOffered] = useState<Ride[]>([]);
  const [showGaps, setShowGaps] = useState(false);

  useFocusEffect(
    useCallback(() => {
      rideRepo.savedPlaces().then(setPlaces).catch(() => setPlaces([]));
      rideRepo.mySchedules().then(setSchedules).catch(() => setSchedules([]));
      rideRepo.myRides().then(setOffered).catch(() => setOffered([]));
    }, [profile.data?.userId]),
  );

  if (profile.isLoading) {
    return (
      <ScreenScaffold>
        <LoadingSkeleton />
      </ScreenScaffold>
    );
  }
  if (profile.isError || !profile.data) {
    return (
      <ScreenScaffold>
        <ErrorView message="Couldn’t load profile" onRetry={() => profile.refetch()} />
      </ScreenScaffold>
    );
  }

  const p = profile.data;
  const name = p.displayName || displayName || 'RideBuddy';
  const city = cityFrom(p.officeLabel) || cityFrom(p.homeLabel);
  const completion = profileCompletion(p, phone);
  const missing = completion.items.filter((item) => !item.done);
  const primaryCar = (vehicles.data ?? []).find((v) => v.primary) ?? (vehicles.data ?? [])[0];
  const liveSchedule = schedules.find((s) => s.active) ?? schedules[0];
  const rideCount = offered.length + (trips.data ?? []).filter((b) => SHARED.has(b.status)).length;
  const buddyCount = new Set((inbox.data ?? []).map((c) => c.peer.userId).filter(Boolean)).size;
  const savedCount = places?.length ?? null;
  const vehicleLine = primaryCar
    ? [vehicleDisplayName(primaryCar), primaryCar.seats ? `${primaryCar.seats} seats` : null]
        .filter(Boolean)
        .join(' · ')
    : null;

  return (
    <ScreenScaffold>
      <ScrollView contentContainerStyle={{ paddingHorizontal: 20, paddingTop: 8, paddingBottom: 40 }}>
        <View style={{ flexDirection: 'row', alignItems: 'center', gap: 14, marginTop: 8 }}>
          <Avatar name={name} uri={p.avatarUrl} size={72} />
          <View style={{ flex: 1, minWidth: 0 }}>
            <Text style={nameStyle} numberOfLines={2}>
              {name}
            </Text>
            <Text style={muted} numberOfLines={1}>
              {[city, 'RideBuddy member'].filter(Boolean).join(' · ')}
            </Text>
          </View>
        </View>

        <Pressable onPress={() => router.push('/profile/edit')} style={editBtn} accessibilityRole="button">
          <Text style={editLabel}>Edit Profile</Text>
        </Pressable>

        <View style={stats}>
          <Stat value={String(rideCount)} label="Rides" />
          <Stat value={String(buddyCount)} label="Buddies" />
          <Stat value={savedCount == null ? '—' : String(savedCount)} label="Saved" />
        </View>

        {completion.percent < 100 ? (
          <View style={[card, { marginTop: 20 }]}>
            <View style={{ flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' }}>
              <Text style={cardTitle}>Complete your profile</Text>
              <Text style={percent}>{completion.percent}%</Text>
            </View>
            <View style={track}>
              <View style={[fill, { width: `${completion.percent}%` }]} />
            </View>
            <Text style={[muted, { marginTop: 10 }]}>
              Add a few details to improve your RideBuddy experience.
            </Text>
            {showGaps ? (
              <View style={{ marginTop: 12, gap: 2 }}>
                {missing.map((item) => (
                  <Pressable
                    key={item.key}
                    onPress={() => router.push(gapRoute(item.key))}
                    style={{ paddingVertical: 8, minHeight: 44, justifyContent: 'center' }}>
                    <Text style={gapItem}>○  {item.label}</Text>
                  </Pressable>
                ))}
              </View>
            ) : null}
            <Pressable
              onPress={() => (showGaps ? router.push('/profile/edit') : setShowGaps(true))}
              style={{ marginTop: 8, paddingVertical: 6, minHeight: 44, justifyContent: 'center' }}>
              <Text style={link}>{showGaps ? 'Edit missing details →' : 'Complete profile →'}</Text>
            </Pressable>
          </View>
        ) : null}

        <Text style={section}>My commute</Text>
        <View style={card}>
          <CommuteRow
            icon="home"
            label="Home"
            value={shortPlace(p.homeLabel)}
            empty="Add your home location"
            onPress={() => router.push('/profile/places')}
          />
          <CommuteRow
            icon="apartment"
            label="Office"
            value={shortPlace(p.officeLabel)}
            empty="Add your office"
            onPress={() => router.push('/profile/places')}
          />
          <CommuteRow
            icon="schedule"
            label="Schedule"
            value={liveSchedule ? formatClock(liveSchedule.departLocalTime) : null}
            empty="Set your commute schedule"
            onPress={() => router.push('/ride/schedules')}
          />
          <CommuteRow
            icon="directions-car"
            label="Vehicle"
            value={vehicleLine}
            empty="Add a vehicle"
            last={!p.canOfferRides}
            onPress={() => router.push('/profile/vehicles')}
          />
          {p.canOfferRides ? (
            <CommuteRow
              icon="event-seat"
              label="Preference"
              value="Can offer rides"
              empty="Ride offering not enabled yet"
              last
              onPress={() => router.push('/profile/vehicles')}
            />
          ) : null}
          <Pressable
            onPress={() => router.push('/profile/places')}
            style={{ marginTop: 4, paddingVertical: 8, minHeight: 44, justifyContent: 'center' }}>
            <Text style={link}>Edit commute →</Text>
          </Pressable>
        </View>

        <Text style={section}>RideBuddy</Text>
        <View style={card}>
          <LinkRow title="My Rides" onPress={() => router.push('/ride')} />
          <LinkRow title="My Schedule" onPress={() => router.push('/ride/schedules')} />
          <LinkRow title="Saved Places" last onPress={() => router.push('/profile/places')} />
        </View>

        <Text style={section}>Community</Text>
        <View style={card}>
          <LinkRow title="My Activity" onPress={() => router.push('/more/activities')} />
          <LinkRow title="My Meetups" onPress={() => router.push('/more/meetups')} />
          <LinkRow title="My Communities" last onPress={() => router.push('/more/community')} />
        </View>

        <Text style={section}>Trust & safety</Text>
        <View style={card}>
          <TrustLine ok={Boolean(phone?.trim())} label="Phone verified" />
          <TrustLine ok={p.employeeVerified} label="Email verified" />
          {p.officeEmailStatus === 'pending' && !p.employeeVerified ? (
            <Text style={[muted, { marginTop: 6 }]}>Workplace email pending</Text>
          ) : null}
          <View style={{ height: 10 }} />
          <LinkRow title="Trust & Verification" onPress={() => router.push('/more/trust')} />
          <LinkRow title="Safety" last onPress={() => router.push('/more/safety')} />
        </View>

        <Text style={section}>Settings</Text>
        <View style={card}>
          <LinkRow title="Notifications" onPress={() => router.push('/profile/settings')} />
          <LinkRow title="Privacy" onPress={() => router.push('/profile/settings')} />
          <LinkRow title="Preferences" last onPress={() => router.push('/profile/settings')} />
        </View>

        <Text style={section}>Account</Text>
        <View style={card}>
          <LinkRow title="Vehicles" onPress={() => router.push('/profile/vehicles')} />
          <LinkRow title="Interests" last onPress={() => router.push('/profile/interests')} />
        </View>

        <Text style={section}>More</Text>
        <View style={card}>
          <LinkRow title="Credits" onPress={() => router.push('/more/credits')} />
          <LinkRow title="Premium" onPress={() => router.push('/more/premium')} />
          <LinkRow title="Insights" last onPress={() => router.push('/more/insights')} />
        </View>

        <Pressable onPress={logout} style={{ marginTop: 20, paddingVertical: 14, minHeight: 48 }}>
          <Text style={[link, { color: colors.danger }]}>Log out</Text>
        </Pressable>
      </ScrollView>
    </ScreenScaffold>
  );
}

function Stat({ value, label }: Readonly<{ value: string; label: string }>) {
  return (
    <View style={{ flex: 1, alignItems: 'center' }}>
      <Text style={statValue}>{value}</Text>
      <Text style={statLabel}>{label}</Text>
    </View>
  );
}

function CommuteRow({
  icon,
  label,
  value,
  empty,
  last,
  onPress,
}: Readonly<{
  icon: keyof typeof MaterialIcons.glyphMap;
  label: string;
  value?: string | null;
  empty: string;
  last?: boolean;
  onPress: () => void;
}>) {
  return (
    <Pressable
      onPress={onPress}
      style={{
        flexDirection: 'row',
        alignItems: 'center',
        gap: 12,
        paddingVertical: 12,
        minHeight: 48,
        borderBottomWidth: last ? 0 : 1,
        borderBottomColor: colors.line,
      }}>
      <MaterialIcons name={icon} size={20} color={value ? colors.brandBlue : colors.inkMuted} />
      <Text style={rowLabel}>{label}</Text>
      <Text style={[rowValue, !value && { color: colors.inkMuted, fontFamily: fonts.body, fontWeight: weights.body }]} numberOfLines={1}>
        {value || empty}
      </Text>
    </Pressable>
  );
}

function LinkRow({ title, onPress, last }: Readonly<{ title: string; onPress: () => void; last?: boolean }>) {
  return (
    <Pressable
      onPress={onPress}
      style={{
        flexDirection: 'row',
        alignItems: 'center',
        paddingVertical: 12,
        borderBottomWidth: last ? 0 : 1,
        borderBottomColor: colors.line,
        minHeight: 48,
      }}>
      <Text style={[rowValue, { flex: 1, textAlign: 'left' }]}>{title}</Text>
      <MaterialIcons name="chevron-right" size={20} color={colors.inkMuted} />
    </Pressable>
  );
}

function TrustLine({ ok, label }: Readonly<{ ok: boolean; label: string }>) {
  return (
    <Text style={[muted, { marginTop: 6, color: ok ? colors.success : colors.inkMuted }]}>
      {ok ? '✓' : '○'} {label}
    </Text>
  );
}

function cityFrom(label?: string | null) {
  if (!label) return '';
  const parts = label.split(',').map((part) => part.trim()).filter(Boolean);
  return parts.at(-1) ?? '';
}

function shortPlace(label?: string | null) {
  const first = label?.split(',')[0]?.trim();
  return first || null;
}

function formatClock(raw: string) {
  const [h, m] = raw.split(':').map(Number);
  if (!Number.isFinite(h) || !Number.isFinite(m)) return raw.slice(0, 5);
  const hour = h % 12 || 12;
  return `${hour}:${String(m).padStart(2, '0')} ${h >= 12 ? 'PM' : 'AM'}`;
}

function gapRoute(key: string) {
  if (key === 'email') return '/profile/email';
  if (key === 'interests') return '/profile/interests';
  if (key === 'home' || key === 'office' || key === 'city') return '/profile/places';
  return '/profile/edit';
}

const nameStyle = {
  fontFamily: fonts.display,
  fontWeight: weights.display,
  fontSize: 26,
  color: colors.ink,
} as const;
const muted = {
  fontFamily: fonts.body,
  fontWeight: weights.body,
  fontSize: 14,
  color: colors.inkMuted,
  marginTop: 4,
} as const;
const editBtn = {
  marginTop: 16,
  alignSelf: 'flex-start' as const,
  paddingHorizontal: 16,
  paddingVertical: 9,
  minHeight: 40,
  borderRadius: 999,
  borderWidth: 1,
  borderColor: colors.line,
  backgroundColor: colors.surfaceElevated,
};
const editLabel = {
  fontFamily: fonts.bodySemi,
  fontWeight: weights.bodySemi,
  fontSize: 14,
  color: colors.ink,
} as const;
const stats = {
  flexDirection: 'row' as const,
  marginTop: 22,
  paddingVertical: 16,
  borderTopWidth: 1,
  borderBottomWidth: 1,
  borderColor: colors.line,
};
const statValue = {
  fontFamily: fonts.displaySemi,
  fontWeight: weights.displaySemi,
  fontSize: 20,
  color: colors.ink,
} as const;
const statLabel = {
  fontFamily: fonts.body,
  fontWeight: weights.body,
  fontSize: 12,
  color: colors.inkMuted,
  marginTop: 3,
} as const;
const section = {
  fontFamily: fonts.bodySemi,
  fontWeight: weights.bodySemi,
  fontSize: 12,
  letterSpacing: 0.6,
  textTransform: 'uppercase' as const,
  color: colors.inkMuted,
  marginTop: 28,
  marginBottom: 10,
} as const;
const card = {
  backgroundColor: colors.surfaceElevated,
  borderWidth: 1,
  borderColor: colors.line,
  borderRadius: 16,
  paddingHorizontal: 16,
  paddingVertical: 12,
} as const;
const cardTitle = {
  fontFamily: fonts.bodySemi,
  fontWeight: weights.bodySemi,
  fontSize: 15,
  color: colors.ink,
} as const;
const percent = {
  fontFamily: fonts.bodySemi,
  fontWeight: weights.bodySemi,
  fontSize: 15,
  color: colors.brandBlue,
} as const;
const track = {
  height: 6,
  backgroundColor: colors.line,
  borderRadius: 6,
  marginTop: 10,
  overflow: 'hidden' as const,
};
const fill = { height: 6, backgroundColor: colors.brandBlue, borderRadius: 6 };
const link = {
  fontFamily: fonts.bodySemi,
  fontWeight: weights.bodySemi,
  fontSize: 14,
  color: colors.brandBlue,
} as const;
const gapItem = {
  fontFamily: fonts.body,
  fontWeight: weights.body,
  fontSize: 14,
  color: colors.ink,
} as const;
const rowLabel = {
  fontFamily: fonts.body,
  fontWeight: weights.body,
  fontSize: 14,
  color: colors.inkMuted,
  width: 86,
} as const;
const rowValue = {
  fontFamily: fonts.bodySemi,
  fontWeight: weights.bodySemi,
  fontSize: 15,
  color: colors.ink,
  flex: 1,
  textAlign: 'right' as const,
} as const;
