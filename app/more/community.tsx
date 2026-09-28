import { ScrollView, Text, View } from 'react-native';

import { ScreenScaffold } from '@/src/components/v2/primitives';
import { hasSavedCommute } from '@/src/lib/commute';
import { useProfile } from '@/src/store/query';
import { colors, fonts } from '@/src/theme/colors';

export default function CommunityScreen() {
  const profile = useProfile();
  const commute = hasSavedCommute(profile.data);

  return (
    <ScreenScaffold>
      <ScrollView contentContainerStyle={{ padding: 20 }}>
        <Text style={{ fontFamily: fonts.display, fontSize: 28, color: colors.ink }}>Commute Circles</Text>
        <Text style={{ fontFamily: fonts.body, color: colors.inkMuted, marginTop: 8 }}>
          If you keep traveling the same route, RideBuddy can suggest a regular group.
        </Text>
        <View style={{ marginTop: 24, padding: 20, borderRadius: 20, backgroundColor: `${colors.brandBlue}10` }}>
          <Text style={{ fontFamily: fonts.displaySemi, fontSize: 20, color: colors.ink }}>
            {commute ? 'Home → Office' : 'No regular route yet'}
          </Text>
          <Text style={{ fontFamily: fonts.body, color: colors.inkMuted, marginTop: 8 }}>
            {commute
              ? 'Save a few more shared rides and this can become a circle with today’s rides, members, and a calendar.'
              : 'Add Home and Office to start a circle later.'}
          </Text>
        </View>
      </ScrollView>
    </ScreenScaffold>
  );
}
