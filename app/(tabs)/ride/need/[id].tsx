import { router, useLocalSearchParams } from 'expo-router';
import { useCallback, useEffect, useState } from 'react';
import { Alert, ScrollView, View } from 'react-native';

import { NeedPostCard, RidePostCard } from '@/src/components/ride/cards';
import { EmptyState, ErrorBanner, OutlineButton, PrimaryButton, SectionLabel, SkyScaffold } from '@/src/components/ui/kit';
import { RideOffer, RideRequest } from '@/src/models/types';
import { chatRepo } from '@/src/services/chatRepository';
import { rideRepo } from '@/src/services/rideRepository';
import { shareTextToWhatsApp } from '@/src/services/whatsappShare';
import { messageFrom, useAuth } from '@/src/store/auth';
import { useRideRevision } from '@/src/store/query';

export default function NeedDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const { userId } = useAuth();
  const { bump } = useRideRevision();
  const [need, setNeed] = useState<RideRequest | null>(null);
  const [offers, setOffers] = useState<RideOffer[]>([]);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async () => {
    if (!id) return;
    try {
      const [n, o] = await Promise.all([rideRepo.getNeed(id), rideRepo.needOffers(id)]);
      setNeed(n);
      setOffers(o);
    } catch (e) {
      setError(messageFrom(e));
    }
  }, [id]);

  useEffect(() => {
    void load();
  }, [load]);

  const isOwner = need?.requesterId === userId;

  return (
    <SkyScaffold>
      <ScrollView contentContainerStyle={{ padding: 20, gap: 12 }}>
        {error ? <ErrorBanner message={error} /> : null}
        {need ? <NeedPostCard need={need} isOwner={isOwner} /> : null}
        <PrimaryButton label="See matching rides" onPress={() => router.push(`/ride/available/${id}`)} />
        <OutlineButton
          label="Share request"
          onPress={async () => {
            try {
              const share = await rideRepo.shareNeed(id);
              await shareTextToWhatsApp(String(share.text ?? share.message ?? ''));
            } catch (e) {
              setError(messageFrom(e));
            }
          }}
        />
        {isOwner && need?.status === 'open' ? (
          <OutlineButton
            danger
            label="Cancel request"
            onPress={() =>
              Alert.alert('Cancel request?', 'Hosts will no longer see this ask.', [
                { text: 'Keep' },
                {
                  text: 'Cancel',
                  style: 'destructive',
                  onPress: async () => {
                    await rideRepo.cancelNeed(id);
                    bump();
                    router.back();
                  },
                },
              ])
            }
          />
        ) : null}
        <SectionLabel>Offers</SectionLabel>
        {offers.length === 0 ? (
          <EmptyState title="No offers yet" subtitle="Hosts on your route can send a seat" />
        ) : (
          offers.map((o) => (
            <View key={o.id} style={{ gap: 8 }}>
              {o.ride ? <RidePostCard ride={o.ride} onPress={() => router.push(`/ride/detail/${o.rideId}`)} /> : null}
              {isOwner && o.status === 'pending' ? (
                <View style={{ flexDirection: 'row', gap: 8 }}>
                  <View style={{ flex: 1 }}>
                    <PrimaryButton
                      label="Accept"
                      onPress={async () => {
                        await rideRepo.decideOffer(o.id, true);
                        bump();
                        await load();
                      }}
                    />
                  </View>
                  <View style={{ flex: 1 }}>
                    <OutlineButton
                      danger
                      label="Decline"
                      onPress={async () => {
                        await rideRepo.decideOffer(o.id, false);
                        await load();
                      }}
                    />
                  </View>
                </View>
              ) : null}
              <OutlineButton
                label="Message"
                onPress={async () => {
                  const conv = await chatRepo.open({ offerId: o.id });
                  router.push(`/chat/${conv.id}`);
                }}
              />
            </View>
          ))
        )}
      </ScrollView>
    </SkyScaffold>
  );
}
