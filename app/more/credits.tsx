import { ScrollView, Text, View } from 'react-native';

import { ScreenScaffold } from '@/src/components/v2/primitives';
import { useMyTrips } from '@/src/store/query';
import { colors, fonts } from '@/src/theme/colors';

export default function CreditsScreen() {
  const trips = useMyTrips();
  const completed = (trips.data ?? []).filter((b) => b.status === 'accepted' || b.status === 'completed').length;
  const credits = completed * 40;

  return (
    <ScreenScaffold>
      <ScrollView contentContainerStyle={{ padding: 20 }}>
        <Text style={{ fontFamily: fonts.bodySemi, letterSpacing: 1.2, color: colors.inkMuted }}>RIDEBUDDY CREDITS</Text>
        <Text style={{ fontFamily: fonts.displayExtra, fontSize: 56, color: colors.ink, marginTop: 8 }}>{credits.toLocaleString()}</Text>
        <Text style={{ fontFamily: fonts.body, color: colors.inkMuted }}>Not trust. Not a rating. Just participation.</Text>
        <View style={{ flexDirection: 'row', gap: 12, marginTop: 24 }}>
          <Tile label="This month" value={`+${credits}`} />
          <Tile label="Estimated reward" value="—" hint="No fixed cash conversion" />
        </View>
        <Text style={{ fontFamily: fonts.displaySemi, fontSize: 18, color: colors.ink, marginTop: 28 }}>Recent activity</Text>
        {completed ? (
          <Text style={{ fontFamily: fonts.body, color: colors.ink, marginTop: 10 }}>+40 × {completed} joined / completed rides</Text>
        ) : (
          <Text style={{ fontFamily: fonts.body, color: colors.inkMuted, marginTop: 10 }}>Complete a shared ride to earn credits.</Text>
        )}
      </ScrollView>
    </ScreenScaffold>
  );
}

function Tile({ label, value, hint }: { label: string; value: string; hint?: string }) {
  return (
    <View style={{ flex: 1, padding: 16, borderRadius: 18, backgroundColor: `${colors.brandOrange}14` }}>
      <Text style={{ fontFamily: fonts.body, color: colors.inkMuted }}>{label}</Text>
      <Text style={{ fontFamily: fonts.display, fontSize: 24, color: colors.ink, marginTop: 4 }}>{value}</Text>
      {hint ? <Text style={{ fontFamily: fonts.body, fontSize: 12, color: colors.inkMuted, marginTop: 4 }}>{hint}</Text> : null}
    </View>
  );
}
