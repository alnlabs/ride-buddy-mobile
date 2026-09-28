import { Stack } from 'expo-router';

import { colors, fonts } from '@/src/theme/colors';

export default function ChatLayout() {
  return (
    <Stack
      screenOptions={{
        headerTitleStyle: { fontFamily: fonts.displaySemi, color: colors.ink },
        headerShadowVisible: false,
        headerStyle: { backgroundColor: colors.skyTop },
        headerBackButtonDisplayMode: 'minimal',
      }}>
      <Stack.Screen name="index" options={{ title: 'Messages' }} />
      <Stack.Screen name="[id]" options={{ title: 'Chat' }} />
    </Stack>
  );
}
