import { LinearGradient } from 'expo-linear-gradient';
import { StyleSheet, View } from 'react-native';

import { colors } from '@/src/theme/colors';

type Props = Readonly<{ energy?: number }>;

/** Atmospheric network field — not a search map. */
export function MovementField({ energy = 0 }: Props) {
  const lit = Math.min(6, Math.max(2, energy || 2));

  return (
    <View style={styles.field}>
      <LinearGradient
        colors={['#C9DCFF', '#E4EEF8', '#F4F7FB', colors.surface]}
        locations={[0, 0.38, 0.72, 1]}
        style={StyleSheet.absoluteFill}
      />
      <View style={[styles.land, { top: '18%', left: '8%', width: 160, height: 90 }]} />
      <View style={[styles.land, { top: '42%', right: '4%', width: 200, height: 120, opacity: 0.45 }]} />
      <View style={[styles.land, { top: '58%', left: '22%', width: 140, height: 70, opacity: 0.35 }]} />

      <View style={[styles.path, styles.pathA]} />
      <View style={[styles.path, styles.pathB]} />
      <View style={[styles.path, styles.pathC]} />
      <View style={[styles.path, styles.pathD]} />

      {NODES.slice(0, lit).map((node) => (
        <View key={node.id} style={[styles.node, { top: node.top, left: node.left }]}>
          <View style={[styles.halo, { backgroundColor: `${node.color}33` }]} />
          <View style={[styles.dot, { backgroundColor: node.color }]} />
        </View>
      ))}
    </View>
  );
}

const NODES = [
  { id: 'a', top: '26%' as const, left: '20%' as const, color: colors.brandBlue },
  { id: 'b', top: '44%' as const, left: '56%' as const, color: colors.brandOrange },
  { id: 'c', top: '60%' as const, left: '32%' as const, color: colors.brandBlue },
  { id: 'd', top: '34%' as const, left: '76%' as const, color: colors.brandOrange },
  { id: 'e', top: '70%' as const, left: '68%' as const, color: colors.brandBlue },
  { id: 'f', top: '22%' as const, left: '48%' as const, color: colors.brandOrange },
];

const styles = StyleSheet.create({
  field: {
    flex: 1,
    overflow: 'hidden',
  },
  land: {
    position: 'absolute',
    borderRadius: 80,
    backgroundColor: '#D5E4F6',
  },
  path: {
    position: 'absolute',
    height: 2,
    borderRadius: 2,
    opacity: 0.42,
  },
  pathA: {
    width: '72%',
    top: '36%',
    left: '6%',
    backgroundColor: colors.brandBlue,
    transform: [{ rotate: '-11deg' }],
  },
  pathB: {
    width: '58%',
    top: '51%',
    left: '24%',
    backgroundColor: colors.brandOrange,
    transform: [{ rotate: '16deg' }],
  },
  pathC: {
    width: '44%',
    top: '64%',
    left: '14%',
    backgroundColor: colors.brandBlue,
    transform: [{ rotate: '-7deg' }],
  },
  pathD: {
    width: '36%',
    top: '28%',
    left: '48%',
    backgroundColor: colors.brandOrange,
    opacity: 0.28,
    transform: [{ rotate: '8deg' }],
  },
  node: {
    position: 'absolute',
    width: 22,
    height: 22,
    alignItems: 'center',
    justifyContent: 'center',
  },
  halo: {
    position: 'absolute',
    width: 22,
    height: 22,
    borderRadius: 11,
  },
  dot: {
    width: 8,
    height: 8,
    borderRadius: 4,
  },
});
