import { router, useLocalSearchParams } from 'expo-router';
import { useEffect, useState } from 'react';
import { ScrollView, Text, View } from 'react-native';

import { OsmMap } from '@/src/components/maps/OsmMap';
import { ErrorBanner, PrimaryButton } from '@/src/components/ui/kit';
import { ScreenScaffold } from '@/src/components/v2/primitives';
import { useOfficeRegion } from '@/src/hooks/useOfficeRegion';
import { formatKm, routeMatchPercent } from '@/src/lib/commute';
import { Ride } from '@/src/models/types';
import { fetchDriveRoutes } from '@/src/services/routing';
import { rideRepo } from '@/src/services/rideRepository';
import { messageFrom } from '@/src/store/auth';
import { colors, fonts } from '@/src/theme/colors';

export default function RouteMatchScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const region = useOfficeRegion();
  const [ride, setRide] = useState<Ride | null>(null);
  const [memberRoute, setMemberRoute] = useState<{ latitude: number; longitude: number }[]>([]);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!id) return;
    rideRepo.getRide(id).then(setRide).catch((e) => setError(messageFrom(e)));
  }, [id]);

  useEffect(() => {
    const from = region.data?.home;
    const to = region.data?.office;
    if (!from || !to) return;
    fetchDriveRoutes({ lat: from.lat, lng: from.lng }, { lat: to.lat, lng: to.lng }).then((list) => {
      setMemberRoute(list[0]?.points ?? []);
    });
  }, [region.data?.home?.lat, region.data?.office?.lat]);

  const hostRoute =
    ride?.routeGeometry?.map((p) => ({ latitude: p[0], longitude: p[1] })) ??
    (ride
      ? [
          { latitude: ride.originLat, longitude: ride.originLng },
          { latitude: ride.destinationLat, longitude: ride.destinationLng },
        ]
      : []);
  const percent = ride ? routeMatchPercent(ride) : 0;
  const detour = ride?.detourKm ?? 2;
  const extraMin = Math.max(3, Math.round(detour * 2.5));

  return (
    <ScreenScaffold tone="map">
      <View style={{ flex: 1 }}>
        <OsmMap
          flex
          points={
            ride
              ? [
                  { latitude: ride.originLat, longitude: ride.originLng, title: 'Host start', color: colors.brandBlue },
                  { latitude: ride.destinationLat, longitude: ride.destinationLng, title: 'Host end', color: colors.brandBlue },
                  ...(region.data?.home
                    ? [{ latitude: region.data.home.lat, longitude: region.data.home.lng, title: 'Your pickup', color: colors.brandOrange }]
                    : []),
                  ...(region.data?.office
                    ? [{ latitude: region.data.office.lat, longitude: region.data.office.lng, title: 'Your drop', color: colors.brandOrange }]
                    : []),
                ]
              : []
          }
          routes={[
            { points: hostRoute, color: colors.brandBlue, width: 5 },
            ...(memberRoute.length ? [{ points: memberRoute, color: colors.brandOrange, width: 4 }] : []),
          ]}
        />
        <ScrollView style={panel} contentContainerStyle={{ padding: 20, paddingBottom: 36 }}>
          <Text style={{ fontFamily: fonts.bodySemi, letterSpacing: 1.2, fontSize: 11, color: colors.inkMuted }}>ROUTE MATCH</Text>
          <Text style={{ fontFamily: fonts.display, fontSize: 28, color: colors.ink, marginTop: 4 }}>How the routes overlap</Text>
          {error ? <ErrorBanner message={error} /> : null}
          <View style={{ flexDirection: 'row', gap: 16, marginTop: 12 }}>
            <Legend color={colors.brandBlue} label="Ride Host" />
            <Legend color={colors.brandOrange} label="Your commute" />
          </View>
          <Stat label="Your pickup" value="Near host route" hint="Exact home stays private" />
          <Stat label="Your drop" value="Near destination" hint="Office area only" />
          <Stat label="Host route overlap" value={`${percent}%`} />
          <Stat label="Estimated host detour" value={`+${formatKm(detour)}`} />
          <Stat label="Estimated extra time" value={`+${extraMin} min`} />
          <View style={{ height: 16 }} />
          <PrimaryButton label="Request to Join" onPress={() => router.push(`/ride/detail/${id}`)} />
        </ScrollView>
      </View>
    </ScreenScaffold>
  );
}

function Legend({ color, label }: { color: string; label: string }) {
  return (
    <View style={{ flexDirection: 'row', alignItems: 'center', gap: 6 }}>
      <View style={{ width: 16, height: 4, borderRadius: 2, backgroundColor: color }} />
      <Text style={{ fontFamily: fonts.bodySemi, color: colors.ink }}>{label}</Text>
    </View>
  );
}

function Stat({ label, value, hint }: { label: string; value: string; hint?: string }) {
  return (
    <View style={{ paddingVertical: 12, borderBottomWidth: 1, borderBottomColor: colors.line }}>
      <Text style={{ fontFamily: fonts.body, color: colors.inkMuted }}>{label}</Text>
      <Text style={{ fontFamily: fonts.displaySemi, fontSize: 20, color: colors.ink, marginTop: 2 }}>{value}</Text>
      {hint ? <Text style={{ fontFamily: fonts.body, color: colors.inkMuted, marginTop: 2 }}>{hint}</Text> : null}
    </View>
  );
}

const panel = {
  maxHeight: '48%' as const,
  backgroundColor: colors.surfaceElevated,
  borderTopLeftRadius: 24,
  borderTopRightRadius: 24,
};
