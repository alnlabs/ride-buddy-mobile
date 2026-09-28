import { ScrollView, Text, View } from 'react-native';

import { PrimaryButton } from '@/src/components/ui/kit';
import { ScreenScaffold } from '@/src/components/v2/primitives';
import { colors, fonts } from '@/src/theme/colors';

export default function PremiumScreen() {
  return (
    <ScreenScaffold>
      <ScrollView contentContainerStyle={{ padding: 20 }}>
        <Text style={{ fontFamily: fonts.display, fontSize: 30, color: colors.ink }}>Get more from your daily commute.</Text>
        <Text style={{ fontFamily: fonts.body, color: colors.inkMuted, marginTop: 8, marginBottom: 24 }}>
          Free RideBuddy already finds and shares rides. Premium is optional polish — never a paywall on carpooling.
        </Text>
        <Block title="Free" items={['Find, offer, and join rides', 'Recurring commute', 'Basic route matching', 'Saved places', 'Activities and meetups']} />
        <Block
          title="Premium"
          items={['Ad-free', 'Advanced route matching and filters', 'Route comparison', 'Commute analytics', 'Smarter alerts']}
        />
        <PrimaryButton label="Try Premium" />
      </ScrollView>
    </ScreenScaffold>
  );
}

function Block({ title, items }: { title: string; items: string[] }) {
  return (
    <View style={{ marginBottom: 20 }}>
      <Text style={{ fontFamily: fonts.displaySemi, fontSize: 18, color: colors.brandBlue }}>{title}</Text>
      {items.map((item) => (
        <Text key={item} style={{ fontFamily: fonts.body, color: colors.ink, marginTop: 8 }}>
          {item}
        </Text>
      ))}
    </View>
  );
}
