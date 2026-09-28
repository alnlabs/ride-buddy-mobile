import { MaterialIcons } from '@expo/vector-icons';
import { Redirect, Tabs } from 'expo-router';
import { Pressable, StyleSheet, Text, View } from 'react-native';

import { CreateSheet } from '@/src/components/v2/CreateSheet';
import { CreateSheetProvider, useCreateSheet } from '@/src/store/createSheet';
import { useAuth } from '@/src/store/auth';
import { colors, fonts, weights } from '@/src/theme/colors';

function CreateTabButton() {
  const { show } = useCreateSheet();
  return (
    <Pressable onPress={show} style={styles.createWrap} accessibilityRole="button" accessibilityLabel="Create">
      <View style={styles.fab}>
        <MaterialIcons name="add" size={28} color="#fff" />
      </View>
      <Text style={styles.createLabel}>Create</Text>
    </Pressable>
  );
}

function TabsInner() {
  const { isAuthenticated, initializing } = useAuth();
  if (!initializing && !isAuthenticated) return <Redirect href="/login" />;

  return (
    <>
      <Tabs
        screenOptions={{
          headerShown: false,
          tabBarActiveTintColor: colors.brandBlue,
          tabBarInactiveTintColor: colors.inkMuted,
          tabBarLabelStyle: { fontFamily: fonts.bodySemi, fontWeight: weights.bodySemi, fontSize: 11 },
          tabBarStyle: {
            height: 78,
            paddingTop: 8,
            borderTopColor: colors.line,
            backgroundColor: colors.surfaceElevated,
          },
        }}>
        <Tabs.Screen
          name="home"
          options={{
            title: 'Home',
            tabBarLabel: 'Home',
            tabBarIcon: ({ color }) => <MaterialIcons name="home" size={24} color={color} />,
          }}
        />
        <Tabs.Screen
          name="ride"
          options={{
            title: 'Rides',
            tabBarLabel: 'Rides',
            tabBarIcon: ({ color }) => <MaterialIcons name="directions-car" size={24} color={color} />,
          }}
        />
        <Tabs.Screen
          name="create"
          options={{
            title: 'Create',
            tabBarLabel: () => null,
            tabBarButton: () => <CreateTabButton />,
          }}
        />
        <Tabs.Screen
          name="activity"
          options={{
            title: 'Activity',
            tabBarLabel: 'Activity',
            tabBarIcon: ({ color }) => <MaterialIcons name="notifications-none" size={24} color={color} />,
          }}
        />
        <Tabs.Screen
          name="profile"
          options={{
            title: 'Profile',
            tabBarLabel: 'Profile',
            tabBarIcon: ({ color }) => <MaterialIcons name="person-outline" size={24} color={color} />,
          }}
        />
        <Tabs.Screen name="discover" options={{ href: null }} />
      </Tabs>
      <CreateSheet />
    </>
  );
}

export default function TabsLayout() {
  return (
    <CreateSheetProvider>
      <TabsInner />
    </CreateSheetProvider>
  );
}

const styles = StyleSheet.create({
  createWrap: { flex: 1, alignItems: 'center', justifyContent: 'flex-start', marginTop: -18 },
  fab: {
    width: 56,
    height: 56,
    borderRadius: 28,
    backgroundColor: colors.brandBlue,
    alignItems: 'center',
    justifyContent: 'center',
  },
  createLabel: {
    marginTop: 4,
    fontFamily: fonts.bodySemi,
    fontWeight: weights.bodySemi,
    fontSize: 11,
    color: colors.brandBlue,
  },
});
