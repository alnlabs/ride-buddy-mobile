import { ScrollView, Text, View } from 'react-native';

import { ScreenScaffold } from '@/src/components/v2/primitives';
import { useMyTrips } from '@/src/store/query';
import { colors, fonts } from '@/src/theme/colors';

export default function InsightsScreen() {
  const trips = useMyTrips();
  const rides = (trips.data ?? []).length;
  const km = rides * 18;
  const savings = rides * 80;

  return (
    <ScreenScaffold>
      <ScrollView contentContainerStyle={{ padding: 20 }}>
        <Text style={{ fontFamily: fonts.bodySemi, color: colors.inkMuted, letterSpacing: 1.2 }}>MY COMMUTE INSIGHTS</Text>
        <Text style={{ fontFamily: fonts.display, fontSize: 32, color: colors.ink, marginTop: 6 }}>This month</Text>
        <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: 12, marginTop: 20 }}>
          <Stat value={String(rides)} label="Rides" wide />
          <Stat value={`${km} km`} label="Distance shared" />
          <Stat value={`₹${savings}`} label="Estimated savings" />
          <Stat value={`${Math.round(km * 0.12)} kg`} label="Estimated CO₂ avoided" />
        </View>
        <View style={{ height: 160, marginTop: 24, borderRadius: 20, backgroundColor: `${colors.brandBlue}14`, justifyContent: 'flex-end', padding: 16 }}>
          <View style={{ height: 8, backgroundColor: colors.brandBlue, width: `${Math.min(100, 20 + rides * 12)}%`, borderRadius: 8 }} />
          <Text style={{ fontFamily: fonts.body, color: colors.inkMuted, marginTop: 10 }}>Ride reliability trend (placeholder until analytics land)</Text>
        </View>
      </ScrollView>
    </ScreenScaffold>
  );
}

function Stat({ value, label, wide }: { value: string; label: string; wide?: boolean }) {
  return (
    <View style={{ width: wide ? '100%' : '47%', padding: 16, borderRadius: 18, backgroundColor: colors.surfaceElevated, borderWidth: 1, borderColor: colors.line }}>
      <Text style={{ fontFamily: fonts.display, fontSize: 28, color: colors.ink }}>{value}</Text>
      <Text style={{ fontFamily: fonts.body, color: colors.inkMuted, marginTop: 4 }}>{label}</Text>
    </View>
  );
}
