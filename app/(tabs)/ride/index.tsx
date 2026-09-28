import { router } from 'expo-router';
import { format, isSameDay, parse } from 'date-fns';
import { useCallback, useEffect, useMemo, useState } from 'react';
import { Pressable, RefreshControl, ScrollView, Text, View } from 'react-native';

import { PlaceSearchField } from '@/src/components/maps/PlaceSearchField';
import { EmptyState, ErrorBanner, PrimaryButton } from '@/src/components/ui/kit';
import { WhenField } from '@/src/components/ui/WhenField';
import { CalendarMonth } from '@/src/components/v2/CalendarMonth';
import { FilterChip, HostTrust, MatchBadge, ScreenScaffold, SegmentedControl } from '@/src/components/v2/primitives';
import { useOfficeRegion } from '@/src/hooks/useOfficeRegion';
import { arrivalFrom, routeMatchPercent } from '@/src/lib/commute';
import { Booking, PlaceSuggestion, Ride, RideSchedule } from '@/src/models/types';
import { rideRepo } from '@/src/services/rideRepository';
import { messageFrom, useAuth } from '@/src/store/auth';
import { useMyTrips, useRideRevision } from '@/src/store/query';
import { takeRideSearchDraft } from '@/src/store/rideSearch';
import { colors, fonts } from '@/src/theme/colors';

type Pane = 'find' | 'mine' | 'calendar';
type MineFilter = 'upcoming' | 'requested' | 'joined' | 'offered' | 'completed';

export default function RidesTab() {
  const [pane, setPane] = useState<Pane>('find');
  return (
    <ScreenScaffold>
      <View style={{ paddingHorizontal: 20, paddingTop: 8 }}>
        <Text style={{ fontFamily: fonts.display, fontSize: 30, color: colors.ink }}>Rides</Text>
        <Text style={{ fontFamily: fonts.body, color: colors.inkMuted, marginTop: 4, marginBottom: 14 }}>
          Find a seat or manage the ones you share.
        </Text>
        <SegmentedControl
          value={pane}
          onChange={(id) => setPane(id as Pane)}
          options={[
            { id: 'find', label: 'Find' },
            { id: 'mine', label: 'My Rides' },
            { id: 'calendar', label: 'Calendar' },
          ]}
        />
      </View>
      {pane === 'find' ? <FindPane /> : pane === 'mine' ? <MinePane /> : <CalendarPane />}
    </ScreenScaffold>
  );
}

function FindPane() {
  const region = useOfficeRegion();
  const [from, setFrom] = useState<PlaceSuggestion | null>(null);
  const [to, setTo] = useState<PlaceSuggestion | null>(null);
  const [when, setWhen] = useState(() => new Date(Date.now() + 60 * 60 * 1000));
  const [rides, setRides] = useState<Ride[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [verifiedOnly, setVerifiedOnly] = useState(false);

  useEffect(() => {
    const draft = takeRideSearchDraft();
    if (!draft) return;
    setFrom(draft.from);
    setTo(draft.to);
    setWhen(draft.when);
    void runSearch(draft.from, draft.to);
  }, []);

  const runSearch = async (origin = from, dest = to) => {
    if (!origin || !dest) {
      setError('Choose From and To');
      return;
    }
    setLoading(true);
    setError(null);
    try {
      setRides(
        await rideRepo.searchRides({
          originLat: origin.lat,
          originLng: origin.lng,
          destinationLat: dest.lat,
          destinationLng: dest.lng,
        }),
      );
    } catch (e) {
      setError(messageFrom(e));
    } finally {
      setLoading(false);
    }
  };

  const visible = (rides ?? []).filter((r) => (verifiedOnly ? r.poster?.employeeVerified : true));

  return (
    <ScrollView contentContainerStyle={{ padding: 20, paddingBottom: 40 }} refreshControl={<RefreshControl refreshing={loading} onRefresh={() => void runSearch()} />}>
      <PlaceSearchField
        label="From"
        value={from}
        searchCity={region.data?.city}
        nearLat={region.data?.lat}
        nearLng={region.data?.lng}
        onSelected={setFrom}
      />
      <View style={{ height: 10 }} />
      <PlaceSearchField
        label="To"
        value={to}
        searchCity={region.data?.city}
        nearLat={from?.lat ?? region.data?.lat}
        nearLng={from?.lng ?? region.data?.lng}
        onSelected={setTo}
      />
      <WhenField value={when} onChange={setWhen} minimumDate={new Date()} />
      <View style={{ height: 12 }} />
      <PrimaryButton label={loading ? 'Searching…' : 'Search'} loading={loading} onPress={() => void runSearch()} />
      <ScrollView horizontal showsHorizontalScrollIndicator={false} style={{ marginTop: 14 }} contentContainerStyle={{ gap: 8 }}>
        <FilterChip label="Verified members" active={verifiedOnly} onPress={() => setVerifiedOnly((v) => !v)} />
        <FilterChip label="Route match" />
        <FilterChip label="Seats" />
        <FilterChip label="Contribution" />
      </ScrollView>
      {error ? <View style={{ marginTop: 12 }}><ErrorBanner message={error} /></View> : null}
      <View style={{ height: 18 }} />
      {rides && visible.length === 0 ? (
        <EmptyState title="No rides on this route" subtitle="Offer yours, or post a need so hosts can find you" actionLabel="I need a ride" onAction={() => router.push('/ride/search')} />
      ) : null}
      {visible.map((ride) => (
        <RideSearchCard key={ride.id} ride={ride} />
      ))}
    </ScrollView>
  );
}

function RideSearchCard({ ride }: { ride: Ride }) {
  const percent = routeMatchPercent(ride);
  const arrival = arrivalFrom(ride.departAt, ride.routeDurationS);
  return (
    <Pressable onPress={() => router.push(`/ride/detail/${ride.id}`)} style={result}>
      <Text style={title}>
        {ride.originLabel} → {ride.destinationLabel}
      </Text>
      <Text style={{ fontFamily: fonts.body, color: colors.inkMuted, marginTop: 4 }}>
        {format(ride.departAt, 'h:mm a')} → {format(arrival, 'h:mm a')}
      </Text>
      <View style={{ height: 12 }} />
      <HostTrust name={ride.poster?.displayName ?? 'Ride Host'} verified={ride.poster?.employeeVerified} />
      <View style={{ flexDirection: 'row', justifyContent: 'space-between', marginTop: 12 }}>
        <Text style={{ fontFamily: fonts.bodySemi, color: colors.ink }}>{ride.availableSeats} seats</Text>
        <Text style={{ fontFamily: fonts.bodyBold, color: colors.brandOrange }}>₹{Math.round(ride.pricePerSeat)}</Text>
      </View>
      <View style={{ marginTop: 6 }}>
        <MatchBadge percent={percent} />
      </View>
      {ride.detourKm != null ? (
        <Text style={{ fontFamily: fonts.body, color: colors.inkMuted, marginTop: 4 }}>
          Pickup near host route · host detour +{ride.detourKm.toFixed(1)} km
        </Text>
      ) : null}
      <View style={{ height: 12 }} />
      <PrimaryButton label="Request to Join" onPress={() => router.push(`/ride/detail/${ride.id}`)} />
    </Pressable>
  );
}

function MinePane() {
  const { userId } = useAuth();
  const trips = useMyTrips();
  const { revision } = useRideRevision();
  const [offered, setOffered] = useState<Ride[]>([]);
  const [filter, setFilter] = useState<MineFilter>('upcoming');

  useEffect(() => {
    rideRepo.myRides().then(setOffered).catch(() => setOffered([]));
  }, [revision]);

  const bookings = trips.data ?? [];
  const now = Date.now();
  const rows = useMemo(() => {
    const items: { id: string; title: string; subtitle: string; onPress: () => void }[] = [];
    if (filter === 'offered' || filter === 'upcoming') {
      offered
        .filter((r) => r.status === 'open' || r.status === 'full')
        .forEach((r) => {
          items.push({
            id: `ride-${r.id}`,
            title: `${r.originLabel} → ${r.destinationLabel}`,
            subtitle: `Offered · ${format(r.departAt, 'EEE d MMM, h:mm a')}`,
            onPress: () => router.push(`/ride/detail/${r.id}`),
          });
        });
    }
    bookings.forEach((b) => {
      const future = (b.departAt?.getTime() ?? 0) > now;
      const include =
        (filter === 'upcoming' && future && (b.status === 'accepted' || b.status === 'requested')) ||
        (filter === 'requested' && b.status === 'requested') ||
        (filter === 'joined' && b.status === 'accepted') ||
        (filter === 'completed' && (b.status === 'completed' || !future));
      if (!include) return;
      items.push({
        id: `book-${b.id}`,
        title: `${b.rideOriginLabel ?? 'Ride'} → ${b.rideDestinationLabel ?? ''}`,
        subtitle: `${b.status} · ${b.departAt ? format(b.departAt, 'EEE d MMM, h:mm a') : ''}`.trim(),
        onPress: () => router.push(`/ride/detail/${b.rideId}`),
      });
    });
    return items;
  }, [bookings, offered, filter, now, userId]);

  return (
    <ScrollView contentContainerStyle={{ padding: 20, paddingBottom: 40 }}>
      <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={{ gap: 8, marginBottom: 16 }}>
        {(['upcoming', 'requested', 'joined', 'offered', 'completed'] as MineFilter[]).map((id) => (
          <FilterChip
            key={id}
            label={id[0].toUpperCase() + id.slice(1)}
            active={filter === id}
            onPress={() => setFilter(id)}
          />
        ))}
      </ScrollView>
      {rows.length === 0 ? <EmptyState title="Nothing here yet" subtitle="Search a ride or offer seats" icon="directions-car" /> : null}
      {rows.map((row) => (
        <Pressable key={row.id} onPress={row.onPress} style={box}>
          <Text style={title}>{row.title}</Text>
          <Text style={meta}>{row.subtitle}</Text>
        </Pressable>
      ))}
    </ScrollView>
  );
}

function CalendarPane() {
  const [month, setMonth] = useState(new Date());
  const [selected, setSelected] = useState(new Date());
  const [schedules, setSchedules] = useState<RideSchedule[]>([]);
  const [rides, setRides] = useState<Ride[]>([]);
  const trips = useMyTrips();

  const load = useCallback(async () => {
    try {
      const [mine, open] = await Promise.all([rideRepo.mySchedules(), rideRepo.myRides()]);
      setSchedules(mine);
      setRides(open);
    } catch {
      setSchedules([]);
      setRides([]);
    }
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  const marks = useMemo(() => {
    const map: Record<string, { ride?: boolean; activity?: boolean }> = {};
    rides.forEach((r) => {
      const key = format(r.departAt, 'yyyy-MM-dd');
      map[key] = { ...map[key], ride: true };
    });
    (trips.data ?? []).forEach((b: Booking) => {
      if (!b.departAt) return;
      const key = format(b.departAt, 'yyyy-MM-dd');
      map[key] = { ...map[key], ride: true };
    });
    schedules.filter((s) => s.active).forEach((s) => {
      // Mark today + tomorrow-style recurrence on matching weekdays in this month
      const time = s.departLocalTime;
      for (let i = 1; i <= 31; i += 1) {
        const day = parse(`${format(month, 'yyyy-MM')}-${String(i).padStart(2, '0')} ${time}`, 'yyyy-MM-dd HH:mm', new Date());
        if (Number.isNaN(day.getTime()) || format(day, 'yyyy-MM') !== format(month, 'yyyy-MM')) continue;
        const dow = day.getDay();
        const match =
          s.frequency === 'daily' ||
          (s.frequency === 'weekdays' && dow >= 1 && dow <= 5) ||
          (s.frequency === 'weekends' && (dow === 0 || dow === 6)) ||
          ((s.frequency === 'weekly' || s.frequency === 'custom_days') && s.daysOfWeek.includes(dow));
        if (match) map[format(day, 'yyyy-MM-dd')] = { ...map[format(day, 'yyyy-MM-dd')], ride: true };
      }
    });
    return map;
  }, [rides, trips.data, schedules, month]);

  const dayItems = [
    ...rides.filter((r) => isSameDay(r.departAt, selected)).map((r) => `${r.originLabel} → ${r.destinationLabel} · ${format(r.departAt, 'h:mm a')}`),
    ...schedules
      .filter((s) => s.active)
      .map((s) => `${s.originLabel} → ${s.destinationLabel} · ${s.departLocalTime} · ${s.frequency}`),
  ];

  return (
    <ScrollView contentContainerStyle={{ padding: 20, paddingBottom: 40 }}>
      <View style={{ flexDirection: 'row', gap: 16, marginBottom: 12 }}>
        <Text style={{ fontFamily: fonts.bodySemi, color: colors.brandBlue }}>● Rides</Text>
        <Text style={{ fontFamily: fonts.bodySemi, color: colors.brandOrange }}>● Activities / Meetups</Text>
      </View>
      <CalendarMonth month={month} selected={selected} marks={marks} onSelect={setSelected} onMonthChange={setMonth} />
      <Text style={{ fontFamily: fonts.displaySemi, fontSize: 18, color: colors.ink, marginTop: 20 }}>
        {format(selected, 'EEEE, d MMMM')}
      </Text>
      {dayItems.length === 0 ? (
        <Text style={{ fontFamily: fonts.body, color: colors.inkMuted, marginTop: 8 }}>Nothing scheduled.</Text>
      ) : (
        dayItems.map((line) => (
          <Text key={line} style={{ fontFamily: fonts.body, color: colors.ink, marginTop: 8 }}>
            {line}
          </Text>
        ))
      )}
    </ScrollView>
  );
}

const box = {
  backgroundColor: colors.surfaceElevated,
  borderRadius: 16,
  borderWidth: 1,
  borderColor: colors.line,
  padding: 14,
  marginTop: 10,
};
const result = {
  backgroundColor: colors.surfaceElevated,
  borderRadius: 20,
  borderWidth: 1,
  borderColor: colors.line,
  padding: 16,
  marginBottom: 12,
};
const title = { fontFamily: fonts.displaySemi, fontSize: 16, color: colors.ink } as const;
const meta = { fontFamily: fonts.body, fontSize: 13, color: colors.inkMuted, marginTop: 4 } as const;
