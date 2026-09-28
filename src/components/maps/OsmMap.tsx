import { StyleSheet, View } from 'react-native';
import MapView, { Marker, Polyline, UrlTile, type Region } from 'react-native-maps';

import { colors } from '@/src/theme/colors';

export type MapPoint = { latitude: number; longitude: number; title?: string; color?: string };
export type MapRoute = { points: { latitude: number; longitude: number }[]; color?: string; width?: number };

type Props = {
  height?: number;
  flex?: boolean;
  center?: { latitude: number; longitude: number };
  points?: MapPoint[];
  route?: { latitude: number; longitude: number }[];
  routes?: MapRoute[];
};

const HYD = { latitude: 17.385, longitude: 78.4867 };

export function OsmMap({ height = 220, flex, center, points = [], route = [], routes }: Props) {
  const extras = routes?.flatMap((r) => r.points) ?? [];
  const first = points[0] ?? extras[0] ?? center ?? HYD;
  const region: Region = {
    latitude: first.latitude,
    longitude: first.longitude,
    latitudeDelta: 0.08,
    longitudeDelta: 0.08,
  };
  const lines: MapRoute[] = routes?.length
    ? routes
    : route.length >= 2
      ? [{ points: route, color: colors.brandBlue, width: 4 }]
      : [];

  return (
    <View style={[flex ? styles.flex : styles.wrap, !flex && { height }]}>
      <MapView style={StyleSheet.absoluteFill} initialRegion={region} region={region}>
        <UrlTile
          urlTemplate="https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png"
          maximumZ={19}
        />
        {lines.map((line, i) =>
          line.points.length >= 2 ? (
            <Polyline
              key={i}
              coordinates={line.points}
              strokeColor={line.color ?? colors.brandBlue}
              strokeWidth={line.width ?? 4}
            />
          ) : null,
        )}
        {points.map((p, i) => (
          <Marker
            key={`${p.latitude}-${i}`}
            coordinate={{ latitude: p.latitude, longitude: p.longitude }}
            title={p.title}
            pinColor={p.color ?? (i === 0 ? colors.brandBlue : colors.brandOrange)}
          />
        ))}
      </MapView>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: { borderRadius: 20, overflow: 'hidden', backgroundColor: colors.skyMid },
  flex: { flex: 1, backgroundColor: colors.skyMid },
});
