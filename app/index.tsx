import { Redirect } from 'expo-router';
import { ActivityIndicator, Image, View } from 'react-native';

import { BrandWordmark, Muted, SkyScaffold } from '@/src/components/ui/kit';
import { useAuth } from '@/src/store/auth';
import { colors } from '@/src/theme/colors';

export default function SplashGate() {
  const { initializing, isAuthenticated } = useAuth();

  if (!initializing && isAuthenticated) return <Redirect href="/home" />;
  if (!initializing && !isAuthenticated) return <Redirect href="/login" />;

  return (
    <SkyScaffold>
      <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center', gap: 16 }}>
        <Image source={require('../assets/logos/app_icon.png')} style={{ width: 132, height: 132 }} />
        <BrandWordmark fontSize={40} center />
        <Muted>Share the commute. Save the day.</Muted>
        <ActivityIndicator color={colors.brandBlue} />
      </View>
    </SkyScaffold>
  );
}
