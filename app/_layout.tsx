import {
  DMSans_400Regular,
  DMSans_500Medium,
  DMSans_600SemiBold,
  DMSans_700Bold,
} from '@expo-google-fonts/dm-sans';
import { Outfit_600SemiBold, Outfit_700Bold, Outfit_800ExtraBold, useFonts } from '@expo-google-fonts/outfit';
import { Stack } from 'expo-router';
import * as SplashScreen from 'expo-splash-screen';
import { useEffect } from 'react';
import { Platform } from 'react-native';
import { StatusBar } from 'expo-status-bar';

import { NetworkBanner } from '@/src/components/ui/NetworkBanner';
import { ensurePermissionOnStartup } from '@/src/services/location';
import { AuthProvider } from '@/src/store/auth';
import { QueryProvider, RideRevisionProvider } from '@/src/store/query';
import { colors } from '@/src/theme/colors';

SplashScreen.preventAutoHideAsync();

export default function RootLayout() {
  const [loaded, error] = useFonts(
    Platform.OS === 'web'
      ? {}
      : {
          Outfit_600SemiBold,
          Outfit_700Bold,
          Outfit_800ExtraBold,
          DMSans_400Regular,
          DMSans_500Medium,
          DMSans_600SemiBold,
          DMSans_700Bold,
        },
  );
  const ready = Platform.OS === 'web' || loaded;

  useEffect(() => {
    if (error) throw error;
  }, [error]);

  useEffect(() => {
    if (ready) {
      SplashScreen.hideAsync();
      void ensurePermissionOnStartup();
    }
  }, [ready]);

  if (!ready) return null;

  return (
    <AuthProvider>
      <QueryProvider>
        <RideRevisionProvider>
          <StatusBar style="dark" />
          <NetworkBanner />
          <Stack
            screenOptions={{
              headerShown: false,
              contentStyle: { backgroundColor: colors.surface },
            }}>
            <Stack.Screen name="index" options={{ title: 'Ride Buddy' }} />
            <Stack.Screen name="login" options={{ title: 'Sign in' }} />
            <Stack.Screen name="otp" options={{ title: 'Verify' }} />
            <Stack.Screen name="(tabs)" options={{ title: 'Ride Buddy' }} />
            <Stack.Screen name="tips" options={{ headerShown: true, title: 'Tips & quotes' }} />
            <Stack.Screen name="chat" />
            <Stack.Screen name="more" />
          </Stack>
        </RideRevisionProvider>
      </QueryProvider>
    </AuthProvider>
  );
}
