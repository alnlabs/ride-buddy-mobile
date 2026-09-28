import { ScrollView, Text, View } from 'react-native';

import { HostTrust, ScreenScaffold } from '@/src/components/v2/primitives';
import { useAuth } from '@/src/store/auth';
import { useMyTrips, useProfile } from '@/src/store/query';
import { colors, fonts } from '@/src/theme/colors';

export default function TrustScreen() {
  const { displayName } = useAuth();
  const profile = useProfile();
  const trips = useMyTrips();
  const name = profile.data?.displayName ?? displayName ?? 'You';
  const rides = (trips.data ?? []).filter((b) => b.status === 'accepted' || b.status === 'completed').length;

  return (
    <ScreenScaffold>
      <ScrollView contentContainerStyle={{ padding: 20 }}>
        <Text style={{ fontFamily: fonts.display, fontSize: 28, color: colors.ink }}>RideBuddy Trust</Text>
        <Text style={{ fontFamily: fonts.body, color: colors.inkMuted, marginTop: 8, marginBottom: 20 }}>
          Public profile shows experience — not comments, not credits, not completion %.
        </Text>
        <View style={{ padding: 16, borderRadius: 20, borderWidth: 1, borderColor: colors.line, backgroundColor: colors.surfaceElevated }}>
          <HostTrust name={name} verified={profile.data?.employeeVerified} rides={rides} />
        </View>
        <Text style={{ fontFamily: fonts.body, color: colors.inkMuted, marginTop: 20 }}>
          After a ride, private feedback covers driving, punctuality, communication, courtesy, and pickup. It never appears as a public review thread.
        </Text>
      </ScrollView>
    </ScreenScaffold>
  );
}
