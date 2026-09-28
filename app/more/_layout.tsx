import { Stack } from 'expo-router';

import { colors, fonts } from '@/src/theme/colors';

export default function MoreLayout() {
  return (
    <Stack
      screenOptions={{
        headerTitleStyle: { fontFamily: fonts.displaySemi, color: colors.ink },
        headerTintColor: colors.ink,
        headerShadowVisible: false,
        headerStyle: { backgroundColor: colors.surface },
        headerBackButtonDisplayMode: 'minimal',
      }}>
      <Stack.Screen name="activities" options={{ title: 'Activities' }} />
      <Stack.Screen name="meetups" options={{ title: 'Meetups' }} />
      <Stack.Screen name="marketplace" options={{ title: 'Marketplace' }} />
      <Stack.Screen name="community" options={{ title: 'Communities' }} />
      <Stack.Screen name="credits" options={{ title: 'Credits' }} />
      <Stack.Screen name="premium" options={{ title: 'Premium' }} />
      <Stack.Screen name="insights" options={{ title: 'Insights' }} />
      <Stack.Screen name="safety" options={{ title: 'Safety' }} />
      <Stack.Screen name="radio" options={{ title: 'Radio' }} />
      <Stack.Screen name="trust" options={{ title: 'Trust' }} />
    </Stack>
  );
}
