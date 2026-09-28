import { router, Stack } from 'expo-router';
import { ScrollView, View } from 'react-native';

import { ActionRow, Muted, ScreenTitle, SkyScaffold } from '@/src/components/ui/kit';
import { colors } from '@/src/theme/colors';

export default function DiscoverScreen() {
  return (
    <SkyScaffold>
      <Stack.Screen options={{ title: 'Discover', headerShown: false }} />
      <ScrollView contentContainerStyle={{ padding: 20 }}>
        <ScreenTitle>Discover</ScreenTitle>
        <Muted>Community features beyond your daily commute.</Muted>
        <View style={{ height: 22 }} />
        <ActionRow icon="work-outline" title="Job referrals" subtitle="Refer coworkers · earn credits" onPress={() => router.push('/discover/jobs')} />
        <View style={{ height: 10 }} />
        <ActionRow icon="groups" title="Meetups" subtitle="Interest-based gatherings near you" accent={colors.brandOrange} onPress={() => router.push('/discover/meetups')} />
        <View style={{ height: 10 }} />
        <ActionRow icon="podcasts" title="Rider podcast" subtitle="Listen on your commute" onPress={() => router.push('/discover/podcast')} />
      </ScrollView>
    </SkyScaffold>
  );
}
