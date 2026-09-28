import { router } from 'expo-router';
import { useCallback, useEffect, useState } from 'react';
import { RefreshControl, ScrollView, View } from 'react-native';

import { InboxNeedCard, NeedPostCard } from '@/src/components/ride/cards';
import { EmptyState, Muted, SectionLabel, SkyScaffold, SoftPanel } from '@/src/components/ui/kit';
import { NeedInboxItem, RideRequest } from '@/src/models/types';
import { rideRepo } from '@/src/services/rideRepository';
import { messageFrom, useAuth } from '@/src/store/auth';
import { useRideRevision } from '@/src/store/query';

export default function NeedsInboxScreen() {
  const { userId } = useAuth();
  const { revision, bump } = useRideRevision();
  const [inbox, setInbox] = useState<NeedInboxItem[]>([]);
  const [mine, setMine] = useState<RideRequest[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [offering, setOffering] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const [a, b] = await Promise.all([rideRepo.needsInbox(), rideRepo.myNeeds()]);
      setInbox(a);
      setMine(b.filter((n) => n.status === 'open' || n.status === 'matched'));
      setError(null);
    } catch (e) {
      setError(messageFrom(e));
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void load();
  }, [load, userId, revision]);

  return (
    <SkyScaffold>
      <ScrollView contentContainerStyle={{ padding: 20, gap: 12 }} refreshControl={<RefreshControl refreshing={loading} onRefresh={load} />}>
        <Muted>Co-riders asking for a seat on your routes, plus asks you posted.</Muted>
        <SectionLabel>Seat requests near you</SectionLabel>
        {error ? (
          <SoftPanel><EmptyState title="Couldn’t load inbox" subtitle={error} actionLabel="Retry" onAction={load} /></SoftPanel>
        ) : inbox.length === 0 ? (
          <SoftPanel><EmptyState title="No seat requests" subtitle="When someone needs a ride on your route, it shows up here" icon="inbox" /></SoftPanel>
        ) : (
          inbox.map((item) => (
            <InboxNeedCard
              key={`${item.request.id}-${item.suggestedRideId}`}
              item={item}
              offering={offering}
              onPress={() => router.push(`/ride/need/${item.request.id}`)}
              onOffer={async () => {
                setOffering(true);
                try {
                  await rideRepo.offerSeat(item.request.id, item.suggestedRideId);
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
        <SectionLabel>My requests</SectionLabel>
        {mine.length === 0 ? (
          <SoftPanel><EmptyState title="You haven’t posted a need" actionLabel="I need a ride" onAction={() => router.push('/ride/search')} icon="hail" /></SoftPanel>
        ) : (
          mine.map((n) => <NeedPostCard key={n.id} need={n} isOwner onPress={() => router.push(`/ride/need/${n.id}`)} />)
        )}
        <View />
      </ScrollView>
    </SkyScaffold>
  );
}
