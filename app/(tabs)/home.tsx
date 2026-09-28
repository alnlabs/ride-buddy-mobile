import { isToday } from 'date-fns';
import { useEffect, useMemo, useState } from 'react';
import { Dimensions, ScrollView, Text, View, type TextStyle } from 'react-native';

import { MovementField } from '@/src/components/home/MovementField';
import { ScreenScaffold } from '@/src/components/v2/primitives';
import { useOfficeRegion } from '@/src/hooks/useOfficeRegion';
import { formatKm, greetingFor, hasSavedCommute } from '@/src/lib/commute';
import { Booking, Ride } from '@/src/models/types';
import { rideRepo } from '@/src/services/rideRepository';
import { useAuth } from '@/src/store/auth';
import { useMyTrips, useProfile } from '@/src/store/query';
import { colors, fonts, weights } from '@/src/theme/colors';

const FIELD_H = Math.max(340, Math.round(Dimensions.get('window').height * 0.52));
const SHARED = new Set(['accepted', 'completed']);

export default function HomeTab() {
  const { displayName } = useAuth();
  const profile = useProfile();
  const trips = useMyTrips();
  const region = useOfficeRegion();
  const first = firstName(displayName ?? profile.data?.displayName);
  const commute = hasSavedCommute(profile.data);
  const from = region.data?.home;
  const to = region.data?.office;
  const company = profile.data?.company?.trim();
  const officeShort = to?.publicShort ?? profile.data?.officeLabel?.split(',')[0]?.trim();

  const [nearby, setNearby] = useState<Ride[] | null>(null);
  const [offered, setOffered] = useState<Ride[]>([]);

  useEffect(() => {
    rideRepo.myRides().then(setOffered).catch(() => setOffered([]));
  }, [trips.data]);

  useEffect(() => {
    if (!from || !to) {
      setNearby(null);
      return;
    }
    let cancelled = false;
    rideRepo
      .searchRides({
        originLat: from.lat,
        originLng: from.lng,
        destinationLat: to.lat,
        destinationLng: to.lng,
      })
      .then((list) => {
        if (!cancelled) setNearby(list);
      })
      .catch(() => {
        if (!cancelled) setNearby([]);
      });
    return () => {
      cancelled = true;
    };
  }, [from?.lat, from?.lng, to?.lat, to?.lng]);

  const bookings = trips.data ?? [];
  const shared = useMemo(() => bookings.filter((b) => SHARED.has(b.status)), [bookings]);
  const todayOnRoute = useMemo(() => (nearby ?? []).filter((r) => isToday(r.departAt)), [nearby]);
  const buddiesToday = useMemo(() => uniqueNames(todayOnRoute), [todayOnRoute]);
  const communityKm = useMemo(() => sumKm(todayOnRoute.length ? todayOnRoute : nearby ?? []), [nearby, todayOnRoute]);
  const personalKm = useMemo(() => personalDistanceKm(shared, offered, nearby ?? []), [shared, offered, nearby]);
  const contribution = shared.reduce((sum, b) => sum + (Number.isFinite(b.amount) ? b.amount : 0), 0);
  const hero = communityHero(commute, nearby, todayOnRoute, buddiesToday, communityKm);

  if (profile.isLoading) {
    return (
      <ScreenScaffold tone="map">
        <View style={{ flex: 1 }}>
          <MovementField energy={0} />
        </View>
      </ScreenScaffold>
    );
  }

  return (
    <ScreenScaffold tone="map">
      <ScrollView
        style={{ flex: 1 }}
        contentContainerStyle={{ paddingBottom: 36 }}
        showsVerticalScrollIndicator={false}>
        <View style={{ height: FIELD_H }}>
          <MovementField energy={todayOnRoute.length || nearby?.length || 0} />
          <View style={{ position: 'absolute', left: 28, right: 28, top: 18 }}>
            <Text
              style={{
                fontFamily: fonts.body,
                fontWeight: weights.body,
                fontSize: 13,
                letterSpacing: 2.4,
                color: colors.inkMuted,
                textTransform: 'uppercase',
              }}>
              RideBuddy
            </Text>
            <Text
              style={{
                fontFamily: fonts.display,
                fontWeight: weights.display,
                fontSize: 36,
                lineHeight: 42,
                color: colors.ink,
                letterSpacing: -0.8,
                marginTop: 10,
              }}>
              {greetingFor(first)}
            </Text>
            <Text
              style={{
                fontFamily: fonts.body,
                fontWeight: weights.body,
                fontSize: 17,
                lineHeight: 26,
                color: colors.inkMuted,
                marginTop: 10,
                maxWidth: 300,
              }}>
              People going places. You can join them.
            </Text>
          </View>

          <View style={{ position: 'absolute', left: 28, right: 28, bottom: 20 }}>
            <Text
              style={{
                fontFamily: fonts.displayExtra,
                fontWeight: weights.displayExtra,
                fontSize: hero.figure ? 64 : 28,
                lineHeight: hero.figure ? 68 : 34,
                color: colors.ink,
                letterSpacing: -1.6,
              }}>
              {hero.figure ?? hero.line}
            </Text>
            {hero.figure ? (
              <Text
                style={{
                  fontFamily: fonts.body,
                  fontWeight: weights.body,
                  fontSize: 16,
                  color: colors.inkMuted,
                  marginTop: 4,
                }}>
                {hero.line}
              </Text>
            ) : null}
          </View>
        </View>

        <View style={{ paddingHorizontal: 28, paddingTop: 4, backgroundColor: colors.surface }}>
          <Eyebrow>Around you</Eyebrow>
          {aroundYou({ commute, nearby, todayOnRoute, company, officeShort, communityKm }).map((line) => (
            <Whisper key={line} text={line} />
          ))}

          <Eyebrow style={{ marginTop: 30 }}>Your impact</Eyebrow>
          {shared.length === 0 && personalKm == null ? (
            <Text
              style={{
                fontFamily: fonts.body,
                fontWeight: weights.body,
                fontSize: 16,
                lineHeight: 24,
                color: colors.inkMuted,
                marginTop: 10,
              }}>
              Join or share a ride and this space will hold your real trips — not estimates we invent.
            </Text>
          ) : (
            <Text
              style={{
                fontFamily: fonts.displaySemi,
                fontWeight: weights.displaySemi,
                fontSize: 22,
                lineHeight: 32,
                color: colors.ink,
                marginTop: 10,
              }}>
              {impactLine(shared.length, personalKm, contribution)}
            </Text>
          )}

          <Text
            style={{
              fontFamily: fonts.body,
              fontWeight: weights.body,
              fontSize: 14,
              color: colors.inkMuted,
              marginTop: 40,
              letterSpacing: 0.2,
            }}>
            Find a ride. Share a ride. Commute together.
          </Text>
        </View>
      </ScrollView>
    </ScreenScaffold>
  );
}

function Eyebrow({ children, style }: Readonly<{ children: string; style?: TextStyle }>) {
  return (
    <Text
      style={[
        {
          fontFamily: fonts.bodySemi,
          fontWeight: weights.bodySemi,
          fontSize: 11,
          letterSpacing: 1.6,
          color: colors.inkMuted,
          textTransform: 'uppercase',
        },
        style,
      ]}>
      {children}
    </Text>
  );
}

function Whisper({ text }: Readonly<{ text: string }>) {
  return (
    <Text
      style={{
        fontFamily: fonts.displaySemi,
        fontWeight: weights.displaySemi,
        fontSize: 20,
        lineHeight: 28,
        color: colors.ink,
        marginTop: 14,
      }}>
      {text}
    </Text>
  );
}

function firstName(name?: string | null) {
  const token = name?.trim().split(/\s+/)[0];
  return token || 'there';
}

function uniqueNames(rides: Ride[]) {
  const seen = new Set<string>();
  const names: string[] = [];
  for (const ride of rides) {
    const key = ride.poster?.userId ?? ride.ownerId;
    if (seen.has(key)) continue;
    seen.add(key);
    names.push(ride.poster?.displayName?.trim() || 'A Ride Host');
  }
  return names;
}

function metresOf(ride: Ride) {
  return ride.routeDistanceM != null && Number.isFinite(ride.routeDistanceM) && ride.routeDistanceM > 0
    ? ride.routeDistanceM
    : 0;
}

function sumKm(rides: Ride[]) {
  const metres = rides.reduce((sum, ride) => sum + metresOf(ride), 0);
  return metres > 0 ? metres / 1000 : null;
}

function personalDistanceKm(shared: Booking[], offered: Ride[], nearby: Ride[]) {
  const byId = new Map<string, Ride>();
  for (const ride of [...offered, ...nearby]) byId.set(ride.id, ride);
  const metres = shared.reduce((sum, booking) => {
    const ride = byId.get(booking.rideId);
    return ride ? sum + metresOf(ride) : sum;
  }, 0);
  return metres > 0 ? metres / 1000 : null;
}

function communityHero(
  commute: boolean,
  nearby: Ride[] | null,
  today: Ride[],
  buddies: string[],
  km: number | null,
): { figure?: string; line: string } {
  if (!commute) {
    return { line: 'RideBuddy lights up when people share a route.' };
  }
  if (nearby == null) {
    return { line: 'Watching your usual route.' };
  }
  if (buddies.length > 0) {
    return {
      figure: String(buddies.length),
      line: buddies.length === 1 ? 'RideBuddy commuting on your route today' : 'RideBuddies commuting on your route today',
    };
  }
  if (today.length > 0) {
    return {
      figure: String(today.length),
      line: today.length === 1 ? 'ride shared on your corridor today' : 'rides shared on your corridor today',
    };
  }
  if (nearby.length > 0) {
    return {
      figure: String(nearby.length),
      line: nearby.length === 1 ? 'open ride on your usual route' : 'open rides on your usual route',
    };
  }
  if (km != null) {
    return { figure: formatKm(km), line: 'kilometres already mapped on this corridor' };
  }
  return { line: 'Your usual route is quiet right now.' };
}

function aroundYou({
  commute,
  nearby,
  todayOnRoute,
  company,
  officeShort,
  communityKm,
}: {
  commute: boolean;
  nearby: Ride[] | null;
  todayOnRoute: Ride[];
  company?: string;
  officeShort?: string;
  communityKm: number | null;
}) {
  const lines: string[] = [];
  const sample = todayOnRoute[0] ?? nearby?.[0];
  if (sample) {
    const who = sample.poster?.displayName?.trim() || 'A Ride Host';
    const dest = sample.destinationLabel?.trim();
    lines.push(dest ? `${who} is sharing a seat toward ${dest}` : `${who} is sharing a seat nearby`);
  } else if (!commute) {
    lines.push('Save Home and Office in Profile to see movement on your commute.');
  } else if (nearby) {
    lines.push('No live movement on this route yet.');
  }

  if (communityKm != null) {
    lines.push(`${formatKm(communityKm)} already shared on rides we can measure here.`);
  }

  if (company) {
    lines.push(`Your commute circle is people heading to ${company}.`);
  } else if (officeShort) {
    lines.push(`Your commute circle gathers around ${officeShort}.`);
  }

  lines.push('No activities or meetups are posted on this corridor yet.');
  return lines.slice(0, 3);
}

function impactLine(rides: number, km: number | null, contribution: number) {
  const parts: string[] = [];
  if (rides > 0) parts.push(`${rides} ${rides === 1 ? 'ride' : 'rides'} shared`);
  if (km != null) parts.push(`${formatKm(km)} shared`);
  if (contribution > 0) parts.push(`₹${Math.round(contribution)} seat share`);
  if (km != null) parts.push(`${(km * 0.12).toFixed(1)} kg CO₂ est. avoided`);
  return parts.join('  ·  ');
}
