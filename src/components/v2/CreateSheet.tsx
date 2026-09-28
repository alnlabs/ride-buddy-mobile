import { MaterialIcons } from '@expo/vector-icons';
import { router } from 'expo-router';
import { Modal, Pressable, StyleSheet, Text, View } from 'react-native';

import { useCreateSheet } from '@/src/store/createSheet';
import { colors, fonts } from '@/src/theme/colors';

const actions = [
  { title: 'Offer a Ride', icon: 'directions-car' as const, tint: colors.brandBlue, go: () => router.push('/ride/post') },
  {
    title: 'Recurring Commute',
    icon: 'event-repeat' as const,
    tint: colors.brandBlue,
    go: () => router.push({ pathname: '/ride/post', params: { recurring: '1' } }),
  },
  { title: 'Activity', icon: 'sports-tennis' as const, tint: colors.brandOrange, go: () => router.push('/more/activities') },
  { title: 'Meetup', icon: 'groups' as const, tint: colors.brandOrange, go: () => router.push('/more/meetups') },
  { title: 'Marketplace Listing', icon: 'storefront' as const, tint: colors.brandOrange, go: () => router.push('/more/marketplace') },
];

export function CreateSheet() {
  const { open, hide } = useCreateSheet();

  return (
    <Modal visible={open} transparent animationType="slide" onRequestClose={hide}>
      <Pressable style={styles.backdrop} onPress={hide} />
      <View style={styles.sheet}>
        <View style={styles.handle} />
        <Text style={styles.kicker}>CREATE</Text>
        <Text style={styles.title}>What are you sharing?</Text>
        {actions.map((action) => (
          <Pressable
            key={action.title}
            style={styles.row}
            onPress={() => {
              hide();
              action.go();
            }}>
            <View style={[styles.icon, { backgroundColor: `${action.tint}1A` }]}>
              <MaterialIcons name={action.icon} size={22} color={action.tint} />
            </View>
            <Text style={styles.label}>{action.title}</Text>
            <MaterialIcons name="arrow-forward" size={18} color={colors.inkMuted} />
          </Pressable>
        ))}
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  backdrop: { flex: 1, backgroundColor: 'rgba(15,23,42,0.35)' },
  sheet: {
    backgroundColor: colors.surfaceElevated,
    borderTopLeftRadius: 28,
    borderTopRightRadius: 28,
    paddingHorizontal: 22,
    paddingBottom: 36,
    paddingTop: 10,
  },
  handle: {
    alignSelf: 'center',
    width: 40,
    height: 4,
    borderRadius: 2,
    backgroundColor: colors.line,
    marginBottom: 16,
  },
  kicker: { fontFamily: fonts.bodySemi, fontSize: 11, letterSpacing: 1.4, color: colors.inkMuted },
  title: { fontFamily: fonts.display, fontSize: 26, color: colors.ink, marginTop: 4, marginBottom: 18 },
  row: { flexDirection: 'row', alignItems: 'center', gap: 14, paddingVertical: 14 },
  icon: { width: 44, height: 44, borderRadius: 14, alignItems: 'center', justifyContent: 'center' },
  label: { flex: 1, fontFamily: fonts.displaySemi, fontSize: 17, color: colors.ink },
});
