import { router, useLocalSearchParams } from 'expo-router';
import { format } from 'date-fns';
import { useEffect, useMemo, useState } from 'react';
import { Pressable, ScrollView, Text, View } from 'react-native';

import { OsmMap } from '@/src/components/maps/OsmMap';
import { CarModelIcon } from '@/src/components/vehicle/CarModelIcon';
import { PlaceSearchField } from '@/src/components/maps/PlaceSearchField';
import { RecurrencePicker, type RecurrenceFrequency } from '@/src/components/ride/RecurrencePicker';
import { ErrorBanner, Field, OutlineButton, PrimaryButton } from '@/src/components/ui/kit';
import { WhenField } from '@/src/components/ui/WhenField';
import { ScreenScaffold, StepDots } from '@/src/components/v2/primitives';
import { useOfficeRegion } from '@/src/hooks/useOfficeRegion';
import { distanceLabel, durationLabel } from '@/src/lib/commute';
import { DriveRoute, PlaceSuggestion, Vehicle, vehicleDisplayName } from '@/src/models/types';
import { currentPositionDetailed } from '@/src/services/location';
import { kMaxLocalSearchKm, reverseDetailed, withinLocalTrip } from '@/src/services/nominatim';
import { rideRepo } from '@/src/services/rideRepository';
import { fetchDriveRoutes } from '@/src/services/routing';
import { BackSeatMode, canOfferThreeBack, estimateSeatPrice, maxBackSeatsFor } from '@/src/services/seatPrice';
import { messageFrom } from '@/src/store/auth';
import { useRideRevision, useVehicles } from '@/src/store/query';
import { colors, fonts, weights } from '@/src/theme/colors';

const titles = ['Where are you going?', 'When?', 'Ride details', 'Choose your route'];

export default function OfferRideScreen() {
  const params = useLocalSearchParams<{ recurring?: string }>();
  const region = useOfficeRegion();
  const vehicles = useVehicles();
  const { bump } = useRideRevision();
  const [step, setStep] = useState(0);
  const [from, setFrom] = useState<PlaceSuggestion | null>(null);
  const [to, setTo] = useState<PlaceSuggestion | null>(null);
  const [routes, setRoutes] = useState<DriveRoute[]>([]);
  const [selectedRoute, setSelectedRoute] = useState(0);
  const [preference, setPreference] = useState<'fastest' | 'shortest' | 'notolls'>('fastest');
  const [vehicle, setVehicle] = useState<Vehicle | null>(null);
  const [mode, setMode] = useState<BackSeatMode>('standard3');
  const [depart, setDepart] = useState(() => new Date(Date.now() + 60 * 60 * 1000));
  const [price, setPrice] = useState('');
  const [seats, setSeats] = useState('2');
  const [notes, setNotes] = useState('');
  const [priceManual, setPriceManual] = useState(false);
  const [recurring, setRecurring] = useState(params.recurring === '1');
  const [frequency, setFrequency] = useState<RecurrenceFrequency>('weekdays');
  const [days, setDays] = useState([1, 2, 3, 4, 5]);
  const [dayOfMonth, setDayOfMonth] = useState(new Date().getDate());
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const list = vehicles.data ?? [];
    const primary = list.find((v) => v.primary) ?? list[0];
    if (primary && !vehicle) setVehicle(primary);
  }, [vehicles.data, vehicle]);

  useEffect(() => {
    const r = region.data;
    if (!r?.home || !r.office) return;
    const hour = new Date().getHours();
    setFrom((prev) => prev ?? (hour < 15 ? r.home! : r.office!));
    setTo((prev) => prev ?? (hour < 15 ? r.office! : r.home!));
  }, [region.data]);

  useEffect(() => {
    if (!from || !to || !withinLocalTrip(from.lat, from.lng, to.lat, to.lng)) return;
    let cancelled = false;
    fetchDriveRoutes({ lat: from.lat, lng: from.lng }, { lat: to.lat, lng: to.lng }).then((list) => {
      if (!cancelled) {
        setRoutes(list);
        setSelectedRoute(0);
      }
    });
    return () => {
      cancelled = true;
    };
  }, [from?.lat, from?.lng, to?.lat, to?.lng]);

  const ranked = useMemo(() => rankRoutes(routes), [routes]);
  const route = ranked[preference] ?? routes[selectedRoute] ?? routes[0];

  useEffect(() => {
    if (!route || !vehicle || priceManual) return;
    const seatCount = Number(seats) || maxBackSeatsFor(vehicle.seats, mode);
    setPrice(
      String(
        estimateSeatPrice({
          distanceMeters: route.distanceMeters,
          durationSeconds: route.durationSeconds,
          seats: seatCount,
          departAt: depart,
          backSeatMode: mode,
        }).suggestedPerSeat,
      ),
    );
  }, [route, vehicle, seats, mode, depart, priceManual]);

  const next = () => {
    if (step === 0) {
      if (!from || !to) return setError('Pick From and To');
      if (!withinLocalTrip(from.lat, from.lng, to.lat, to.lng)) {
        return setError(`To must be within ${kMaxLocalSearchKm} km of From`);
      }
    }
    if (step === 2 && !vehicle) return setError('Add a vehicle first');
    setError(null);
    setStep((s) => Math.min(3, s + 1));
  };

  const submit = async () => {
    if (!from || !to || !vehicle) return;
    setSaving(true);
    setError(null);
    try {
      const body = {
        vehicleId: vehicle.id,
        comfortRide: mode === 'spacious2',
        originLat: from.lat,
        originLng: from.lng,
        originLabel: from.publicShort,
        originPublicShort: from.publicShort,
        originFullAddress: from.fullAddress,
        originPrivateLabel: from.privateLabel,
        destinationLat: to.lat,
        destinationLng: to.lng,
        destinationLabel: to.publicShort,
        destinationPublicShort: to.publicShort,
        destinationFullAddress: to.fullAddress,
        destinationPrivateLabel: to.privateLabel,
        availableSeats: Number(seats) || 1,
        pricePerSeat: Number(price) || 0,
        notes,
        routeGeometry: route?.points.map((p) => [p.latitude, p.longitude]),
        routeDistanceM: route?.distanceMeters,
        routeDurationS: route?.durationSeconds,
      };
      if (recurring) {
        await rideRepo.createSchedule({
          kind: 'ride',
          frequency,
          ...(frequency === 'weekly' || frequency === 'custom_days' ? { daysOfWeek: days } : {}),
          ...(frequency === 'monthly' ? { dayOfMonth } : {}),
          departLocalTime: `${String(depart.getHours()).padStart(2, '0')}:${String(depart.getMinutes()).padStart(2, '0')}:00`,
          timezone: 'Asia/Kolkata',
          ...body,
        });
        bump();
        router.replace('/ride/schedules');
        return;
      }
      const created = await rideRepo.createRide({ ...body, departAt: depart.toISOString() });
      bump();
      router.replace(`/ride/co-riders/${created.id}`);
    } catch (e) {
      setError(messageFrom(e));
    } finally {
      setSaving(false);
    }
  };

  return (
    <ScreenScaffold>
      <ScrollView contentContainerStyle={{ padding: 20, paddingBottom: 40 }}>
        <StepDots step={step} total={4} />
        <Text style={{ fontFamily: fonts.bodySemi, fontWeight: weights.bodySemi, color: colors.brandBlue, marginTop: 14 }}>
          OFFER A RIDE
        </Text>
        <Text
          style={{
            fontFamily: fonts.display,
            fontWeight: weights.display,
            fontSize: 28,
            color: colors.ink,
            marginTop: 6,
          }}>
          {titles[step]}
        </Text>

        {step === 0 ? (
          <View style={{ marginTop: 20, gap: 12 }}>
            <PlaceSearchField
              label="From"
              value={from}
              searchCity={region.data?.city}
              nearLat={region.data?.lat}
              nearLng={region.data?.lng}
              onSelected={setFrom}
              onMyLocation={async () => {
                const pos = await currentPositionDetailed();
                if (!pos.ok) return null;
                return reverseDetailed(pos.lat, pos.lng);
              }}
            />
            <PlaceSearchField
              label="To"
              value={to}
              searchCity={region.data?.city}
              nearLat={from?.lat ?? region.data?.lat}
              nearLng={from?.lng ?? region.data?.lng}
              onSelected={setTo}
            />
            {from && to ? (
              <OsmMap
                height={200}
                points={[
                  { latitude: from.lat, longitude: from.lng, title: from.publicShort },
                  { latitude: to.lat, longitude: to.lng, title: to.publicShort },
                ]}
                route={route?.points}
              />
            ) : null}
          </View>
        ) : null}

        {step === 1 ? (
          <View style={{ marginTop: 20, gap: 12 }}>
            <RecurrencePicker
              recurring={recurring}
              onRecurringChanged={setRecurring}
              frequency={frequency}
              onFrequencyChanged={setFrequency}
              selectedDays={days}
              onDaysChanged={setDays}
              dayOfMonth={dayOfMonth}
              onDayOfMonthChanged={setDayOfMonth}
              departTimeLabel={format(depart, 'h:mm a')}
              onDepartTimePressed={() => undefined}
            />
            <WhenField value={depart} onChange={setDepart} minimumDate={new Date()} />
          </View>
        ) : null}

        {step === 2 ? (
          <View style={{ marginTop: 20, gap: 12 }}>
            {(vehicles.data ?? []).length === 0 ? (
              <PrimaryButton label="Add a vehicle" onPress={() => router.push('/profile/vehicles')} />
            ) : (
              (vehicles.data ?? []).map((v) => (
                <Pressable
                  key={v.id}
                  onPress={() => setVehicle(v)}
                  style={[box, vehicle?.id === v.id && boxOn, { flexDirection: 'row', alignItems: 'center', gap: 12 }]}>
                  <CarModelIcon makeModel={v.makeModel} size={48} />
                  <View style={{ flex: 1 }}>
                    <Text style={value}>{vehicleDisplayName(v)}</Text>
                    <Text style={meta}>{v.makeModel} · {v.seats} seats</Text>
                  </View>
                </Pressable>
              ))
            )}
            <Field label="Available seats" value={seats} onChangeText={setSeats} keyboardType="number-pad" />
            <Field
              label="Suggested contribution (₹ / seat)"
              value={price}
              onChangeText={(t) => {
                setPriceManual(true);
                setPrice(t);
              }}
              keyboardType="number-pad"
            />
            <Field label="Pickup notes (optional)" value={notes} onChangeText={setNotes} placeholder="Gate 2, no exact building" />
            {vehicle && canOfferThreeBack(vehicle.seats) ? (
              <Pressable onPress={() => setMode(mode === 'spacious2' ? 'standard3' : 'spacious2')} style={box}>
                <Text style={value}>{mode === 'spacious2' ? 'Comfort · 2 in the back' : 'Standard seating'}</Text>
                <Text style={meta}>Pickup stays approximate. Exact home is private.</Text>
              </Pressable>
            ) : null}
          </View>
        ) : null}

        {step === 3 ? (
          <View style={{ marginTop: 20, gap: 10 }}>
            <OsmMap
              height={220}
              points={
                from && to
                  ? [
                      { latitude: from.lat, longitude: from.lng, title: from.publicShort },
                      { latitude: to.lat, longitude: to.lng, title: to.publicShort },
                    ]
                  : []
              }
              route={route?.points}
            />
            {(['fastest', 'shortest', 'notolls'] as const).map((key) => {
              const option = ranked[key];
              if (!option) return null;
              const label = key === 'fastest' ? 'FASTEST' : key === 'shortest' ? 'SHORTEST' : 'AVOID TOLLS';
              return (
                <Pressable key={key} onPress={() => setPreference(key)} style={[box, preference === key && boxOn]}>
                  <Text style={{ fontFamily: fonts.bodySemi, color: colors.brandBlue, letterSpacing: 1 }}>{label}</Text>
                  <Text style={value}>
                    {durationLabel(option.durationSeconds)} · {distanceLabel(option.distanceMeters)} · ₹0 tolls
                  </Text>
                  {option.trafficDelaySeconds > 60 ? (
                    <Text style={meta}>+{Math.round(option.trafficDelaySeconds / 60)} min traffic</Text>
                  ) : null}
                </Pressable>
              );
            })}
            <Text style={meta}>The selected route becomes the RideBuddy intended route. Tolls show ₹0 until a live toll source is connected.</Text>
          </View>
        ) : null}

        {error ? <View style={{ marginTop: 12 }}><ErrorBanner message={error} /></View> : null}
        <View style={{ flexDirection: 'row', gap: 10, marginTop: 20 }}>
          {step > 0 ? (
            <View style={{ flex: 1 }}>
              <OutlineButton label="Back" onPress={() => setStep((s) => s - 1)} />
            </View>
          ) : null}
          <View style={{ flex: 2 }}>
            {step < 3 ? (
              <PrimaryButton label="Continue" onPress={next} />
            ) : (
              <PrimaryButton label={recurring ? 'Save commute' : 'Publish ride'} loading={saving} onPress={submit} />
            )}
          </View>
        </View>
      </ScrollView>
    </ScreenScaffold>
  );
}

function rankRoutes(routes: DriveRoute[]) {
  if (!routes.length) return {} as Record<'fastest' | 'shortest' | 'notolls', DriveRoute | undefined>;
  const fastest = [...routes].sort((a, b) => a.durationSeconds - b.durationSeconds)[0];
  const shortest = [...routes].sort((a, b) => a.distanceMeters - b.distanceMeters)[0];
  const notolls = [...routes].sort((a, b) => a.distanceMeters - b.distanceMeters)[0];
  return { fastest, shortest, notolls };
}

const box = {
  backgroundColor: colors.surfaceElevated,
  borderRadius: 16,
  borderWidth: 1,
  borderColor: colors.line,
  padding: 14,
};
const boxOn = { borderColor: colors.brandBlue, backgroundColor: `${colors.brandBlue}0D` };
const meta = { fontFamily: fonts.body, fontSize: 13, color: colors.inkMuted, marginTop: 4 } as const;
const value = { fontFamily: fonts.displaySemi, fontSize: 16, color: colors.ink } as const;
