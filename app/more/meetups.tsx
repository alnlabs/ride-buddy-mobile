import { ScrollView, Text, View } from 'react-native';

import { ScreenScaffold } from '@/src/components/v2/primitives';
import { colors, fonts } from '@/src/theme/colors';

export default function MeetupsScreen() {
  return (
    <ScreenScaffold>
      <ScrollView contentContainerStyle={{ padding: 20 }}>
        <Text style={{ fontFamily: fonts.display, fontSize: 30, color: colors.ink }}>Local meetups</Text>
        <Text style={{ fontFamily: fonts.body, color: colors.inkMuted, marginTop: 8 }}>
          Community events for people who already share a commute. Not dating.
        </Text>
        <View style={{ marginTop: 28, padding: 20, borderRadius: 20, backgroundColor: `${colors.brandOrange}14` }}>
          <Text style={{ fontFamily: fonts.bodySemi, color: colors.brandOrange }}>THIS WEEKEND</Text>
          <Text style={{ fontFamily: fonts.display, fontSize: 24, color: colors.ink, marginTop: 8 }}>No meetups posted yet</Text>
          <Text style={{ fontFamily: fonts.body, color: colors.inkMuted, marginTop: 8 }}>
            When a commute circle forms, a simple event can live here.
          </Text>
        </View>
      </ScrollView>
    </ScreenScaffold>
  );
}
