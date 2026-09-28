import { Link, Stack } from 'expo-router';
import { Text, View } from 'react-native';

import { colors, fonts } from '@/src/theme/colors';

export default function NotFound() {
  return (
    <>
      <Stack.Screen options={{ title: 'Not found' }} />
      <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center', gap: 12 }}>
        <Text style={{ fontFamily: fonts.displaySemi, color: colors.ink }}>This screen doesn’t exist.</Text>
        <Link href="/home">
          <Text style={{ color: colors.brandBlue, fontFamily: fonts.bodySemi }}>Go home</Text>
        </Link>
      </View>
    </>
  );
}
