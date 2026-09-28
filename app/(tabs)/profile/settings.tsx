import { router } from 'expo-router';
import { useEffect, useState } from 'react';
import { Switch, Text, View } from 'react-native';

import { ActionRow, SectionLabel, SkyScaffold, SoftPanel } from '@/src/components/ui/kit';
import { homeSpotlight } from '@/src/services/homeSpotlight';
import { colors, fonts } from '@/src/theme/colors';

export default function SettingsScreen() {
  const [enabled, setEnabled] = useState(true);

  useEffect(() => {
    homeSpotlight.tipsEnabled().then(setEnabled);
  }, []);

  return (
    <SkyScaffold>
      <View style={{ padding: 20, gap: 12 }}>
        <SectionLabel>Home</SectionLabel>
        <SoftPanel>
          <View style={{ flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' }}>
            <View style={{ flex: 1, paddingRight: 12 }}>
              <Text style={{ fontFamily: fonts.bodySemi, color: colors.ink }}>Show daily tip or quote on Home</Text>
              <Text style={{ fontFamily: fonts.body, color: colors.inkMuted, marginTop: 4 }}>Popup once per day, then pinned on Home</Text>
            </View>
            <Switch
              value={enabled}
              onValueChange={async (v) => {
                setEnabled(v);
                await homeSpotlight.setTipsEnabled(v);
              }}
            />
          </View>
        </SoftPanel>
        <ActionRow icon="lightbulb-outline" title="Browse tips & quotes" subtitle="App, safety, manners, co-riders & quotes" accent={colors.brandOrange} onPress={() => router.push('/tips')} />
      </View>
    </SkyScaffold>
  );
}
