import { router } from 'expo-router';
import { format } from 'date-fns';
import { Pressable, ScrollView, Text, View } from 'react-native';

import { EmptyState, LoadingSkeleton } from '@/src/components/ui/kit';
import { GroupLabel, ScreenScaffold } from '@/src/components/v2/primitives';
import { NeedInboxItem } from '@/src/models/types';
import { rideRepo } from '@/src/services/rideRepository';
import { useChatInbox, useMyTrips, useSeatRequestCount } from '@/src/store/query';
import { colors, fonts } from '@/src/theme/colors';
import { useEffect, useState } from 'react';

export default function ActivityTab() {
  const inbox = useChatInbox();
  const trips = useMyTrips();
  const seats = useSeatRequestCount();
  const [needs, setNeeds] = useState<NeedInboxItem[]>([]);

  useEffect(() => {
    rideRepo.needsInbox().then(setNeeds).catch(() => setNeeds([]));
  }, [seats.data]);

  if (inbox.isLoading || trips.isLoading) {
    return (
      <ScreenScaffold>
        <LoadingSkeleton />
      </ScreenScaffold>
    );
  }

  const unread = (inbox.data ?? []).filter((c) => c.unreadCount > 0);
  const pending = (trips.data ?? []).filter((b) => b.status === 'requested');
  const confirmed = (trips.data ?? []).filter((b) => b.status === 'accepted');
  const completed = (trips.data ?? []).filter((b) => b.status === 'completed');

  return (
    <ScreenScaffold>
      <ScrollView contentContainerStyle={{ padding: 20, paddingBottom: 40 }}>
        <Text style={{ fontFamily: fonts.display, fontSize: 30, color: colors.ink }}>Activity</Text>
        <Text style={{ fontFamily: fonts.body, color: colors.inkMuted, marginTop: 4, marginBottom: 22 }}>
          What needs you — then what already happened.
        </Text>

        <GroupLabel>NEEDS ATTENTION</GroupLabel>
        {needs.length === 0 && unread.length === 0 && pending.length === 0 ? (
          <EmptyState title="You're all caught up" subtitle="Join requests and ride changes will land here" icon="notifications-none" />
        ) : null}
        {needs.map((item) => (
          <Line
            key={item.request.id}
            accent={colors.brandOrange}
            title="Join request on your route"
            body={`${item.request.poster?.displayName ?? 'Someone'} · ${item.request.originLabel} → ${item.request.destinationLabel}`}
            onPress={() => router.push('/ride/needs')}
          />
        ))}
        {pending.map((b) => (
          <Line
            key={b.id}
            accent={colors.brandBlue}
            title="Ride request waiting"
            body={`${b.rideOriginLabel ?? 'Ride'} · ${b.departAt ? format(b.departAt, 'EEE h:mm a') : ''}`}
            onPress={() => router.push(`/ride/detail/${b.rideId}`)}
          />
        ))}
        {unread.map((c) => (
          <Line
            key={c.id}
            accent={colors.brandOrange}
            title={`Message from ${c.peer.displayName}`}
            body={c.lastMessagePreview ?? 'New message'}
            onPress={() => router.push(`/chat/${c.id}`)}
          />
        ))}

        <View style={{ height: 22 }} />
        <GroupLabel>UPDATES</GroupLabel>
        {confirmed.map((b) => (
          <Line
            key={`ok-${b.id}`}
            accent={colors.matchGood}
            title="Ride confirmed"
            body={`${b.rideOriginLabel ?? 'Ride'} → ${b.rideDestinationLabel ?? ''}`}
            onPress={() => router.push(`/ride/detail/${b.rideId}`)}
          />
        ))}
        {completed.map((b) => (
          <Line
            key={`done-${b.id}`}
            accent={colors.inkMuted}
            title="Ride completed"
            body="How was your ride? Private feedback stays off the public profile."
            onPress={() => router.push(`/ride/detail/${b.rideId}`)}
          />
        ))}
        {confirmed.length === 0 && completed.length === 0 ? (
          <Text style={{ fontFamily: fonts.body, color: colors.inkMuted, marginTop: 4 }}>No ride updates yet.</Text>
        ) : null}

        <View style={{ height: 22 }} />
        <GroupLabel>REWARDS</GroupLabel>
        <Pressable onPress={() => router.push('/more/credits')} style={reward}>
          <Text style={{ fontFamily: fonts.displaySemi, fontSize: 16, color: colors.ink }}>RideBuddy Credits</Text>
          <Text style={{ fontFamily: fonts.body, color: colors.inkMuted, marginTop: 4 }}>
            Earned from completed rides and useful profile steps — not a trust score.
          </Text>
        </Pressable>
      </ScrollView>
    </ScreenScaffold>
  );
}

function Line({
  title,
  body,
  onPress,
  accent,
}: {
  title: string;
  body: string;
  onPress: () => void;
  accent: string;
}) {
  return (
    <Pressable onPress={onPress} style={row}>
      <View style={{ width: 8, height: 8, borderRadius: 4, backgroundColor: accent, marginTop: 6 }} />
      <View style={{ flex: 1 }}>
        <Text style={{ fontFamily: fonts.bodySemi, fontSize: 15, color: colors.ink }}>{title}</Text>
        <Text style={{ fontFamily: fonts.body, fontSize: 13, color: colors.inkMuted, marginTop: 2 }}>{body}</Text>
      </View>
    </Pressable>
  );
}

const row = {
  flexDirection: 'row' as const,
  gap: 12,
  paddingVertical: 12,
  borderBottomWidth: 1,
  borderBottomColor: colors.line,
};
const reward = {
  marginTop: 8,
  padding: 16,
  borderRadius: 18,
  backgroundColor: `${colors.brandOrange}14`,
};
