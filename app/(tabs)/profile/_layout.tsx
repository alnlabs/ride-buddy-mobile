import { Stack } from 'expo-router';

import { colors, fonts, weights } from '@/src/theme/colors';

export default function ProfileLayout() {
  return (
    <Stack
      screenOptions={{
        headerTitleStyle: { fontFamily: fonts.displaySemi, fontWeight: weights.displaySemi, color: colors.ink },
        headerShadowVisible: false,
        headerStyle: { backgroundColor: colors.skyTop },
        headerBackButtonDisplayMode: 'minimal',
      }}>
      <Stack.Screen name="index" options={{ headerShown: false, title: 'Profile' }} />
      <Stack.Screen name="view" options={{ title: 'View profile' }} />
      <Stack.Screen name="edit" options={{ title: 'Edit profile' }} />
      <Stack.Screen name="places" options={{ title: 'Saved Places' }} />
      <Stack.Screen name="work" options={{ title: 'Role & company' }} />
      <Stack.Screen name="email" options={{ title: 'Email' }} />
      <Stack.Screen name="interests" options={{ title: 'Interests' }} />
      <Stack.Screen name="vehicles" options={{ title: 'My vehicles' }} />
      <Stack.Screen name="settings" options={{ title: 'Settings' }} />
    </Stack>
  );
}
