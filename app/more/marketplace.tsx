import { ScrollView, Text, View } from 'react-native';

import { FilterChip, ScreenScaffold } from '@/src/components/v2/primitives';
import { colors, fonts } from '@/src/theme/colors';

export default function MarketplaceScreen() {
  return (
    <ScreenScaffold>
      <ScrollView contentContainerStyle={{ padding: 20 }}>
        <Text style={{ fontFamily: fonts.display, fontSize: 30, color: colors.ink }}>Marketplace</Text>
        <Text style={{ fontFamily: fonts.body, color: colors.inkMuted, marginTop: 6, marginBottom: 16 }}>
          Buy, sell, or exchange with people on your route. Secondary to carpooling.
        </Text>
        <View style={{ flexDirection: 'row', gap: 8, marginBottom: 16 }}>
          <FilterChip label="Buy" active />
          <FilterChip label="Sell" />
          <FilterChip label="Exchange" />
        </View>
        <View style={{ height: 140, borderRadius: 16, backgroundColor: colors.skyMid, marginBottom: 12 }} />
        <View style={{ height: 140, borderRadius: 16, backgroundColor: colors.skyMid }} />
        <Text style={{ fontFamily: fonts.body, color: colors.inkMuted, marginTop: 16 }}>No listings yet.</Text>
      </ScrollView>
    </ScreenScaffold>
  );
}
