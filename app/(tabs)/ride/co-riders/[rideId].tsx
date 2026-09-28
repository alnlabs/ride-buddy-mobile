import { router, useLocalSearchParams } from 'expo-router';
import { useCallback, useEffect, useState } from 'react';
import { ScrollView } from 'react-native';

import { OsmMap } from '@/src/components/maps/OsmMap';
import { InboxNeedCard } from '@/src/components/ride/cards';
import { EmptyState, ErrorBanner, SkyScaffold } from '@/src/components/ui/kit';
import { NeedInboxItem, Ride } from '@/src/models/types';
import { rideRepo } from '@/src/services/rideRepository';
import { messageFrom } from '@/src/store/auth';
import { useRideRevision } from '@/src/store/query';

export default function FindCoRidersScreen() {
  const { rideId } = useLocalSearchParams<{ rideId: string }>();
  const { bump } = useRideRevision();
  const [ride, setRide] = useState<Ride | null>(null);
  const [items, setItems] = useState<NeedInboxItem[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [offering, setOffering] = useState(false);

  const load = useCallback(async () => {
    if (!rideId) return;
    try {
      const [r, list] = await Promise.all([rideRepo.getRide(rideId), rideRepo.rideMatchingNeeds(rideId)]);
      setRide(r);
      setItems(list);
    } catch (e) {
      setError(messageFrom(e));
    }
  }, [rideId]);

  useEffect(() => {
    void load();
  }, [load]);

  return (
    <SkyScaffold>
      <ScrollView contentContainerStyle={{ padding: 20, gap: 12 }}>
        {error ? <ErrorBanner message={error} /> : null}
        {ride ? (
          <OsmMap
            height={220}
            points={[
              { latitude: ride.originLat, longitude: ride.originLng, title: ride.originLabel },
              { latitude: ride.destinationLat, longitude: ride.destinationLng, title: ride.destinationLabel },
            ]}
          />
        ) : null}
        {items.length === 0 ? (
          <EmptyState title="No matching requests" subtitle="Share your ride — coworkers can still join" />
        ) : (
          items.map((item) => (
            <InboxNeedCard
              key={item.request.id}
              item={item}
              offering={offering}
              onPress={() => router.push(`/ride/need/${item.request.id}`)}
              onOffer={async () => {
                setOffering(true);
                try {
                  await rideRepo.offerSeat(item.request.id, rideId);
                  bump();
                  await load();
                } catch (e) {
                  setError(messageFrom(e));
                } finally {
                  setOffering(false);
                }
              }}
            />
          ))
        )}
      </ScrollView>
    </SkyScaffold>
  );
}
