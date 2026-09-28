import NetInfo from '@react-native-community/netinfo';
import { useEffect, useState } from 'react';
import { Text, View } from 'react-native';

import { colors, fonts } from '@/src/theme/colors';

export function NetworkBanner() {
  const [offline, setOffline] = useState(false);
  useEffect(() => {
    return NetInfo.addEventListener((s) => {
      setOffline(s.isConnected === false);
    });
  }, []);
  if (!offline) return null;
  return (
    <View style={{ backgroundColor: colors.danger, paddingVertical: 6, paddingHorizontal: 12 }}>
      <Text style={{ color: '#fff', fontFamily: fonts.bodySemi, textAlign: 'center' }}>
        You’re offline — lists may be stale
      </Text>
    </View>
  );
}
