import { ScrollView, Text, View } from 'react-native';

import { showSpotlightDialog } from '@/src/components/tips/HomeSpotlightCard';
import { SectionLabel, SkyScaffold, SoftPanel } from '@/src/components/ui/kit';
import { homeSpotlight } from '@/src/services/homeSpotlight';
import { colors, fonts } from '@/src/theme/colors';

const cats = [
  { id: 'app', label: 'How to use the app' },
  { id: 'safety', label: 'Safety' },
  { id: 'manners', label: 'Manners' },
  { id: 'connect', label: 'Connect' },
];

export default function TipsScreen() {
  return (
    <SkyScaffold>
      <ScrollView contentContainerStyle={{ padding: 20, gap: 12 }}>
        {cats.map((c) => (
          <View key={c.id} style={{ gap: 8 }}>
            <SectionLabel>{c.label}</SectionLabel>
            {homeSpotlight.tipsForCategory(c.id).map((t) => (
              <SoftPanel key={t.id} onPress={() => showSpotlightDialog(t)}>
                <Text style={{ fontFamily: fonts.displaySemi, color: colors.ink }}>{t.title}</Text>
                <Text style={{ fontFamily: fonts.body, color: colors.inkMuted, marginTop: 4 }}>{t.body}</Text>
              </SoftPanel>
            ))}
          </View>
        ))}
        <SectionLabel>Quotes</SectionLabel>
        {homeSpotlight.allQuotes().map((q) => (
          <SoftPanel key={q.id} onPress={() => showSpotlightDialog(q)}>
            <Text style={{ fontFamily: fonts.displaySemi }}>{q.title}</Text>
            <Text style={{ fontFamily: fonts.body, color: colors.inkMuted, marginTop: 4 }}>{q.body}</Text>
            <Text style={{ color: colors.brandOrange, marginTop: 6 }}>— {q.author}</Text>
          </SoftPanel>
        ))}
      </ScrollView>
    </SkyScaffold>
  );
}
