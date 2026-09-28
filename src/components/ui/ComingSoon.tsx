import { MaterialIcons } from '@expo/vector-icons';
import { View } from 'react-native';

import { Muted, ScreenTitle, SkyScaffold, SoftPanel } from '@/src/components/ui/kit';
import { colors } from '@/src/theme/colors';

export function ComingSoon({
  title,
  icon,
  subtitle = 'Coming soon — we’re building this inside Discover.',
}: {
  title: string;
  icon: keyof typeof MaterialIcons.glyphMap;
  subtitle?: string;
}) {
  return (
    <SkyScaffold>
      <View style={{ flex: 1, justifyContent: 'center', padding: 32 }}>
        <SoftPanel>
          <View style={{ alignItems: 'center', gap: 12 }}>
            <View style={{ width: 72, height: 72, borderRadius: 20, backgroundColor: `${colors.brandBlue}1A`, alignItems: 'center', justifyContent: 'center' }}>
              <MaterialIcons name={icon} size={34} color={colors.brandBlue} />
            </View>
            <ScreenTitle>{title}</ScreenTitle>
            <Muted center>{subtitle}</Muted>
          </View>
        </SoftPanel>
      </View>
    </SkyScaffold>
  );
}
