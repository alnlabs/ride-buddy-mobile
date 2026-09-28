import { Stack } from 'expo-router';

import { colors, fonts } from '@/src/theme/colors';

export default function DiscoverLayout() {
  return (
    <Stack
      screenOptions={{
        headerTitleStyle: { fontFamily: fonts.displaySemi, color: colors.ink },
        headerShadowVisible: false,
        headerStyle: { backgroundColor: colors.skyTop },
        headerBackButtonDisplayMode: 'minimal',
      }}>
      <Stack.Screen name="index" options={{ headerShown: false, title: 'Discover' }} />
      <Stack.Screen name="jobs" options={{ title: 'Job referrals' }} />
      <Stack.Screen name="meetups" options={{ title: 'Meetups' }} />
      <Stack.Screen name="podcast" options={{ title: 'Rider podcast' }} />
    </Stack>
  );
}
