import { Image } from 'expo-image';
import { useState } from 'react';
import { Text, View } from 'react-native';

import { resolveCarVisual } from '@/src/data/carIcons';
import { colors, fonts, weights } from '@/src/theme/colors';

type Props = {
  makeModel?: string | null;
  brand?: string;
  model?: string;
  size?: number;
};

/** Real studio photo of that brand + model. Falls back to a mark if the image fails. */
export function CarModelIcon({ makeModel, brand, model, size = 44 }: Props) {
  const visual = resolveCarVisual({ makeModel, brand, model });
  const [failed, setFailed] = useState(false);
  const r = Math.round(size * 0.22);
  const uri = visual.imageUrl;

  return (
    <View
      accessibilityLabel={`${visual.brand} ${visual.model}`}
      style={{
        width: size,
        height: size,
        borderRadius: r,
        backgroundColor: colors.skyMid,
        overflow: 'hidden',
        alignItems: 'center',
        justifyContent: 'center',
        borderWidth: 1,
        borderColor: colors.line,
      }}>
      {!failed && uri ? (
        <Image
          source={{ uri }}
          style={{ width: size, height: size }}
          contentFit="contain"
          cachePolicy="memory-disk"
          recyclingKey={uri}
          onError={() => setFailed(true)}
        />
      ) : (
        <View
          style={{
            width: size,
            height: size,
            backgroundColor: visual.brandColor,
            alignItems: 'center',
            justifyContent: 'center',
          }}>
          <Text
            style={{
              fontFamily: fonts.bodyBold,
              fontWeight: weights.bodyBold,
              fontSize: Math.max(9, size * 0.28),
              color: '#F8FAFC',
            }}>
            {visual.code}
          </Text>
        </View>
      )}
    </View>
  );
}
