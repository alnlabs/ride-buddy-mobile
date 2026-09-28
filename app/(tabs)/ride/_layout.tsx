import { Stack } from 'expo-router';

import { colors, fonts, weights } from '@/src/theme/colors';

export default function RideLayout() {
  return (
    <Stack
      screenOptions={{
        headerTitleStyle: { fontFamily: fonts.displaySemi, fontWeight: weights.displaySemi, color: colors.ink },
        headerTintColor: colors.ink,
        headerShadowVisible: false,
        headerStyle: { backgroundColor: colors.skyTop },
        headerBackButtonDisplayMode: 'minimal',
      }}>
      <Stack.Screen name="index" options={{ headerShown: false, title: 'Rides' }} />
      <Stack.Screen name="search" options={{ title: 'I need a ride' }} />
      <Stack.Screen name="post" options={{ title: 'Offer a Ride' }} />
      <Stack.Screen name="match/[id]" options={{ title: 'Route match' }} />
      <Stack.Screen name="needs" options={{ title: 'As a host' }} />
      <Stack.Screen name="available/[needId]" options={{ title: 'Matching rides' }} />
      <Stack.Screen name="co-riders/[rideId]" options={{ title: 'Find co-riders' }} />
      <Stack.Screen name="need/[id]" options={{ title: 'Request' }} />
      <Stack.Screen name="detail/[id]" options={{ title: 'Ride' }} />
      <Stack.Screen name="trips" options={{ title: 'As a co-rider' }} />
      <Stack.Screen name="schedules" options={{ title: 'My schedules' }} />
    </Stack>
  );
}
