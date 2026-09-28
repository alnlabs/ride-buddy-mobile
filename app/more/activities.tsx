import { ScrollView, Text, View } from 'react-native';

import { FilterChip, ScreenScaffold } from '@/src/components/v2/primitives';
import { colors, fonts } from '@/src/theme/colors';

const items = ['Badminton', 'Cricket', 'Running', 'Cycling', 'Chess', 'Movies', 'Photography'];

export default function ActivitiesScreen() {
  return (
    <ScreenScaffold>
      <ScrollView contentContainerStyle={{ padding: 20 }}>
        <Text style={{ fontFamily: fonts.display, fontSize: 32, color: colors.brandOrange }}>Play after the commute.</Text>
        <Text style={{ fontFamily: fonts.body, color: colors.inkMuted, marginTop: 8, marginBottom: 18 }}>
          Activities stay secondary to rides. Nearby people, not a social feed.
        </Text>
        <View style={{ flexDirection: 'row', gap: 8, marginBottom: 20 }}>
          <FilterChip label="Nearby" active />
          <FilterChip label="Today" />
          <FilterChip label="This Weekend" />
        </View>
        {items.map((item) => (
          <View key={item} style={{ paddingVertical: 18, borderBottomWidth: 1, borderBottomColor: `${colors.brandOrange}33` }}>
            <Text style={{ fontFamily: fonts.displaySemi, fontSize: 22, color: colors.ink }}>{item}</Text>
            <Text style={{ fontFamily: fonts.body, color: colors.inkMuted, marginTop: 4 }}>Coming soon near your usual route</Text>
          </View>
        ))}
      </ScrollView>
    </ScreenScaffold>
  );
}
