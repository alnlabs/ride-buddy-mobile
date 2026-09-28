import { ScrollView, Text, View } from 'react-native';

import { OutlineButton, PrimaryButton } from '@/src/components/ui/kit';
import { ScreenScaffold } from '@/src/components/v2/primitives';
import { colors, fonts } from '@/src/theme/colors';

export default function SafetyScreen() {
  return (
    <ScreenScaffold>
      <ScrollView contentContainerStyle={{ padding: 24 }}>
        <Text style={{ fontFamily: fonts.display, fontSize: 28, color: colors.ink }}>Stay in control</Text>
        <Text style={{ fontFamily: fonts.body, color: colors.inkMuted, marginTop: 8, marginBottom: 24 }}>
          Safety stays quiet until you need it. Nothing here is a public score.
        </Text>
        <Item title="Before the ride" body="Verification, trust, and approximate pickup points." />
        <Item title="During the ride" body="Share trip, trusted contact, SOS, route deviation." />
        <Item title="After the ride" body="Private feedback and a safety report if something felt wrong." />
        <View style={{ height: 20 }} />
        <PrimaryButton label="Share trip" />
        <View style={{ height: 10 }} />
        <OutlineButton danger label="SOS" />
      </ScrollView>
    </ScreenScaffold>
  );
}

function Item({ title, body }: { title: string; body: string }) {
  return (
    <View style={{ paddingVertical: 14, borderBottomWidth: 1, borderBottomColor: colors.line }}>
      <Text style={{ fontFamily: fonts.displaySemi, fontSize: 18, color: colors.ink }}>{title}</Text>
      <Text style={{ fontFamily: fonts.body, color: colors.inkMuted, marginTop: 4 }}>{body}</Text>
    </View>
  );
}
