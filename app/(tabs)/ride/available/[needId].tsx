import { router, useLocalSearchParams } from 'expo-router';
import { useCallback, useEffect, useState } from 'react';
import { Alert, ScrollView, View } from 'react-native';

import { OsmMap } from '@/src/components/maps/OsmMap';
import { RidePostCard } from '@/src/components/ride/cards';
import { EmptyState, ErrorBanner, PrimaryButton, SkyScaffold, SoftPanel } from '@/src/components/ui/kit';
import { Ride, RideRequest } from '@/src/models/types';
import { rideRepo } from '@/src/services/rideRepository';
import { messageFrom } from '@/src/store/auth';
import { useRideRevision } from '@/src/store/query';

export default function AvailableRidesScreen() {
  const { needId } = useLocalSearchParams<{ needId: string }>();
  const { bump } = useRideRevision();
  const [need, setNeed] = useState<RideRequest | null>(null);
  const [matches, setMatches] = useState<Ride[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [booking, setBooking] = useState(false);

  const load = useCallback(async () => {
    if (!needId) return;
    try {
      const [n, m] = await Promise.all([rideRepo.getNeed(needId), rideRepo.needMatches(needId)]);
      setNeed(n);
      setMatches(m);
    } catch (e) {
      setError(messageFrom(e));
    }
  }, [needId]);

  useEffect(() => {
    void load();
  }, [load]);

  const book = async (ride: Ride) => {
    if (!need) return;
    setBooking(true);
    try {
      await rideRepo.book({
        rideId: ride.id,
        seatsRequested: need.seatsNeeded,
        paymentMethod: 'cash',
        pickupLat: need.originLat,
        pickupLng: need.originLng,
        pickupLabel: need.originLabel,
        dropLat: need.destinationLat,
        dropLng: need.destinationLng,
        dropLabel: need.destinationLabel,
      });
      bump();
      Alert.alert('Requested', 'The host will confirm your seat.');
      router.replace('/ride/trips');
    } catch (e) {
      setError(messageFrom(e));
    } finally {
      setBooking(false);
    }
  };

  return (
    <SkyScaffold>
      <ScrollView contentContainerStyle={{ padding: 20, gap: 12 }}>
        {need ? (
          <OsmMap
            height={260}
            points={[
              { latitude: need.originLat, longitude: need.originLng, title: need.originLabel },
              { latitude: need.destinationLat, longitude: need.destinationLng, title: need.destinationLabel },
              ...matches.map((r) => ({ latitude: r.originLat, longitude: r.originLng, title: r.originLabel })),
            ]}
          />
        ) : null}
        {error ? <ErrorBanner message={error} /> : null}
        {matches.length === 0 ? (
          <SoftPanel>
            <EmptyState title="No matching rides yet" subtitle="Hosts on your route can still offer a seat" actionLabel="View request" onAction={() => router.push(`/ride/need/${needId}`)} />
          </SoftPanel>
        ) : (
          matches.map((ride) => (
            <View key={ride.id} style={{ gap: 8 }}>
              <RidePostCard ride={ride} onPress={() => router.push(`/ride/detail/${ride.id}`)} />
              <PrimaryButton label={booking ? 'Booking…' : 'Request this seat'} loading={booking} onPress={() => book(ride)} />
            </View>
          ))
        )}
      </ScrollView>
    </SkyScaffold>
  );
}
