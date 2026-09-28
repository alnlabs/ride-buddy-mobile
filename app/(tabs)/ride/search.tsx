import { router } from 'expo-router';
import { useEffect, useState } from 'react';
import { Pressable, ScrollView, Switch, Text, View } from 'react-native';

import { PlaceSearchField } from '@/src/components/maps/PlaceSearchField';
import { RecurrencePicker, type RecurrenceFrequency } from '@/src/components/ride/RecurrencePicker';
import { ErrorBanner, Muted, PrimaryButton, SkyScaffold, SoftPanel } from '@/src/components/ui/kit';
import { WhenField } from '@/src/components/ui/WhenField';
import { useOfficeRegion } from '@/src/hooks/useOfficeRegion';
import { PlaceSuggestion } from '@/src/models/types';
import { currentPositionDetailed } from '@/src/services/location';
import { kMaxLocalSearchKm, reverseDetailed, withinLocalTrip } from '@/src/services/nominatim';
import { rideRepo } from '@/src/services/rideRepository';
import { messageFrom } from '@/src/store/auth';
import { useRideRevision } from '@/src/store/query';
import { colors, fonts } from '@/src/theme/colors';
import { format } from 'date-fns';

function placesBody(from: PlaceSuggestion, to: PlaceSuggestion) {
  return {
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
  };
}

export default function SearchRidesScreen() {
  const region = useOfficeRegion();
  const { bump } = useRideRevision();
  const [from, setFrom] = useState<PlaceSuggestion | null>(null);
  const [to, setTo] = useState<PlaceSuggestion | null>(null);
  const [depart, setDepart] = useState(() => new Date(Date.now() + 60 * 60 * 1000));
  const [seats, setSeats] = useState(1);
  const [comfort, setComfort] = useState(false);
  const [recurring, setRecurring] = useState(false);
  const [frequency, setFrequency] = useState<RecurrenceFrequency>('weekdays');
  const [days, setDays] = useState([1, 2, 3, 4, 5]);
  const [dayOfMonth, setDayOfMonth] = useState(new Date().getDate());
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const r = region.data;
    if (!r?.home || !r.office) return;
    const hour = new Date().getHours();
    setFrom(hour < 15 ? r.home : r.office);
    setTo(hour < 15 ? r.office : r.home);
  }, [region.data]);

  const submit = async () => {
    if (!from || !to) {
      setError('Pick From and To from suggestions');
      return;
    }
    if (!withinLocalTrip(from.lat, from.lng, to.lat, to.lng)) {
      setError(`To must be within ${kMaxLocalSearchKm} km of From`);
      return;
    }
    setSaving(true);
    setError(null);
    try {
      if (recurring) {
        await rideRepo.createSchedule({
          kind: 'need',
          frequency,
          ...(frequency === 'weekly' || frequency === 'custom_days' ? { daysOfWeek: days } : {}),
          ...(frequency === 'monthly' ? { dayOfMonth } : {}),
          departLocalTime: `${String(depart.getHours()).padStart(2, '0')}:${String(depart.getMinutes()).padStart(2, '0')}:00`,
          timezone: 'Asia/Kolkata',
          seatsNeeded: seats,
          comfortPreferred: comfort,
          ...placesBody(from, to),
        });
        bump();
        router.replace('/ride/schedules');
        return;
      }
      const need = await rideRepo.createNeed({
        ...placesBody(from, to),
        departAt: depart.toISOString(),
        seatsNeeded: seats,
        comfortPreferred: comfort,
      });
      bump();
      router.replace(`/ride/available/${need.id}`);
    } catch (e) {
      setError(messageFrom(e));
    } finally {
      setSaving(false);
    }
  };

  return (
    <SkyScaffold>
      <ScrollView contentContainerStyle={{ padding: 20, paddingBottom: 40, gap: 12 }}>
        <Muted>Post your trip — then see matching open rides on the map.</Muted>
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
        <SoftPanel>
          <Text style={{ fontFamily: fonts.bodySemi, color: colors.ink }}>Seats needed</Text>
          <View style={{ flexDirection: 'row', gap: 8, marginTop: 8 }}>
            {[1, 2, 3].map((n) => (
              <Pressable key={n} onPress={() => setSeats(n)} style={{ paddingHorizontal: 14, paddingVertical: 8, borderRadius: 10, backgroundColor: seats === n ? `${colors.brandOrange}2E` : colors.skyMid }}>
                <Text style={{ fontFamily: fonts.bodyBold, color: seats === n ? colors.brandOrange : colors.ink }}>{n}</Text>
              </Pressable>
            ))}
          </View>
          <View style={{ flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginTop: 12 }}>
            <Text style={{ fontFamily: fonts.body, color: colors.ink, flex: 1 }}>Prefer comfort (max 2 in back)</Text>
            <Switch value={comfort} onValueChange={setComfort} />
          </View>
        </SoftPanel>
        {error ? <ErrorBanner message={error} /> : null}
        <PrimaryButton
          label={saving ? (recurring ? 'Saving…' : 'Finding rides…') : recurring ? 'Save schedule' : 'Find rides'}
          loading={saving}
          icon={recurring ? 'event-repeat' : 'search'}
          onPress={submit}
        />
      </ScrollView>
    </SkyScaffold>
  );
}
