import { MaterialIcons } from '@expo/vector-icons';
import { Alert, Pressable, StyleSheet, Text, View } from 'react-native';

import { SoftPanel } from '@/src/components/ui/kit';
import { HomeSpotlight } from '@/src/models/types';
import { colors, fonts } from '@/src/theme/colors';

export function HomeSpotlightCard({
  spotlight,
  onDismiss,
  onOpen,
}: {
  spotlight: HomeSpotlight;
  onDismiss: () => void;
  onOpen: () => void;
}) {
  return (
    <SoftPanel onPress={onOpen}>
      <View style={styles.row}>
        <MaterialIcons
          name={spotlight.kind === 'quote' ? 'format-quote' : 'lightbulb-outline'}
          size={22}
          color={colors.brandOrange}
        />
        <View style={{ flex: 1 }}>
          <Text style={styles.kicker}>{spotlight.kind === 'quote' ? 'Quote' : 'Tip'}</Text>
          <Text style={styles.title}>{spotlight.title}</Text>
          <Text style={styles.body} numberOfLines={3}>{spotlight.body}</Text>
        </View>
        <Pressable
          onPress={(e) => {
            e.stopPropagation?.();
            onDismiss();
          }}
          hitSlop={8}>
          <MaterialIcons name="close" size={18} color={colors.inkMuted} />
        </Pressable>
      </View>
    </SoftPanel>
  );
}

export function showSpotlightDialog(spotlight: HomeSpotlight, onCta?: () => void) {
  Alert.alert(
    spotlight.title,
    spotlight.kind === 'quote' && spotlight.author ? `${spotlight.body}\n\n— ${spotlight.author}` : spotlight.body,
    [
      ...(spotlight.ctaLabel && onCta ? [{ text: spotlight.ctaLabel, onPress: onCta }] : []),
      { text: 'Close' },
    ],
  );
}

const styles = StyleSheet.create({
  row: { flexDirection: 'row', gap: 12 },
  kicker: { fontFamily: fonts.bodySemi, color: colors.brandOrange, fontSize: 11, textTransform: 'uppercase' },
  title: { fontFamily: fonts.displaySemi, color: colors.ink, fontSize: 16 },
  body: { fontFamily: fonts.body, color: colors.inkMuted, marginTop: 4 },
});
