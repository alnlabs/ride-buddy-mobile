import { router } from 'expo-router';
import { format } from 'date-fns';
import { ScrollView, Text, View } from 'react-native';

import { EmptyState, ErrorView, LoadingSkeleton, SkyScaffold, SoftPanel } from '@/src/components/ui/kit';
import { chatRepo } from '@/src/services/chatRepository';
import { rideRepo } from '@/src/services/rideRepository';
import { messageFrom } from '@/src/store/auth';
import { useMyTrips } from '@/src/store/query';
import { colors, fonts } from '@/src/theme/colors';

function statusLabel(status: string) {
  switch (status) {
    case 'requested':
      return 'Pending host';
    case 'accepted':
      return 'Confirmed';
    case 'rejected':
      return 'Declined';
    case 'cancelled':
      return 'Cancelled';
    case 'completed':
      return 'Completed';
    default:
      return status;
  }
}

export default function MyTripsScreen() {
  const trips = useMyTrips();
  if (trips.isLoading) return <SkyScaffold><LoadingSkeleton /></SkyScaffold>;
  if (trips.isError) return <SkyScaffold><ErrorView message={messageFrom(trips.error)} onRetry={() => trips.refetch()} /></SkyScaffold>;
  const list = trips.data ?? [];

  return (
    <SkyScaffold>
      <ScrollView contentContainerStyle={{ padding: 20, gap: 12 }}>
        {list.length === 0 ? (
          <SoftPanel>
            <EmptyState title="No trips yet" subtitle="Search and book a ride" actionLabel="Find a ride" onAction={() => router.push('/ride/search')} />
          </SoftPanel>
        ) : (
          list.map((b) => (
            <SoftPanel key={b.id} onPress={() => router.push(`/ride/detail/${b.rideId}`)}>
              <Text style={{ fontFamily: fonts.displaySemi, color: colors.ink }}>
                {b.rideOriginLabel ?? ''} → {b.rideDestinationLabel ?? ''}
              </Text>
              <Text style={{ fontFamily: fonts.body, color: colors.inkMuted, marginTop: 4 }}>
                {statusLabel(b.status)} · {b.paymentMethod} · ₹{Math.round(b.amount)}
                {b.departAt ? ` · ${format(b.departAt, 'MMM d, h:mm a')}` : ''}
              </Text>
              {b.status === 'requested' || b.status === 'accepted' ? (
                <View style={{ marginTop: 10 }}>
                  <Text
                    onPress={async () => {
                      const conv = await chatRepo.open({ bookingId: b.id });
                      router.push(`/chat/${conv.id}`);
                    }}
                    style={{ color: colors.brandBlue, fontFamily: fonts.bodySemi }}>
                    Message host
                  </Text>
                </View>
              ) : null}
            </SoftPanel>
          ))
        )}
      </ScrollView>
    </SkyScaffold>
  );
}

void rideRepo;
