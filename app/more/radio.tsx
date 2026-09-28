import { Text, View } from 'react-native';

import { ScreenScaffold } from '@/src/components/v2/primitives';
import { colors, fonts } from '@/src/theme/colors';

export default function RadioScreen() {
  return (
    <ScreenScaffold tone="ink">
      <View style={{ flex: 1, justifyContent: 'flex-end', padding: 24 }}>
        <Text style={{ fontFamily: fonts.bodySemi, color: colors.brandOrange, letterSpacing: 1.2 }}>RIDEBUDDY RADIO</Text>
        <Text style={{ fontFamily: fonts.display, fontSize: 32, color: '#fff', marginTop: 8 }}>Good company for the road.</Text>
        <View style={{ height: 8, backgroundColor: `${colors.brandOrange}55`, borderRadius: 8, marginTop: 28 }}>
          <View style={{ height: 8, width: '18%', backgroundColor: colors.brandOrange, borderRadius: 8 }} />
        </View>
        <Text style={{ fontFamily: fonts.body, color: '#94A3B8', marginTop: 10 }}>Commute mix · 0:42 / 24:00</Text>
        <Text style={{ fontFamily: fonts.body, color: '#94A3B8', marginTop: 20 }}>
          Music, road tips, and circle updates. Not in the tab bar — play it when you ride.
        </Text>
      </View>
    </ScreenScaffold>
  );
}
