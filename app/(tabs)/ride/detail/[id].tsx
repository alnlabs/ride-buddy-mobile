import { router, useLocalSearchParams } from 'expo-router';
import { format } from 'date-fns';
import { useCallback, useEffect, useState } from 'react';
import { Alert, Pressable, ScrollView, Text, View } from 'react-native';

import { OsmMap } from '@/src/components/maps/OsmMap';
import { ErrorBanner, OutlineButton, PrimaryButton } from '@/src/components/ui/kit';
import { HostTrust, MatchBadge, ScreenScaffold } from '@/src/components/v2/primitives';
import { arrivalFrom, routeMatchPercent } from '@/src/lib/commute';
import { Booking, Ride } from '@/src/models/types';
import { chatRepo } from '@/src/services/chatRepository';
import { rideRepo } from '@/src/services/rideRepository';
import { shareTextToWhatsApp } from '@/src/services/whatsappShare';
import { messageFrom, useAuth } from '@/src/store/auth';
import { useRideRevision } from '@/src/store/query';
import { colors, fonts } from '@/src/theme/colors';

export default function RideDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const { userId } = useAuth();
  const { bump } = useRideRevision();
  const [ride, setRide] = useState<Ride | null>(null);
  const [bookings, setBookings] = useState<Booking[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  const load = useCallback(async () => {
    if (!id) return;
    try {
      const next = await rideRepo.getRide(id);
      setRide(next);
      if (next.ownerId === userId) setBookings(await rideRepo.bookingsForRide(id));
    } catch (e) {
      setError(messageFrom(e));
    }
  }, [id, userId]);

  useEffect(() => {
    void load();
  }, [load]);

  const isOwner = ride?.ownerId === userId;
  const percent = ride ? routeMatchPercent(ride) : 0;
  const arrival = ride ? arrivalFrom(ride.departAt, ride.routeDurationS) : null;

  const requestJoin = async () => {
    if (!ride) return;
    setBusy(true);
    try {
      await rideRepo.book({
        rideId: ride.id,
        seatsRequested: 1,
        paymentMethod: 'cash',
        pickupLat: ride.originLat,
        pickupLng: ride.originLng,
        pickupLabel: ride.originLabel,
        dropLat: ride.destinationLat,
        dropLng: ride.destinationLng,
        dropLabel: ride.destinationLabel,
      });
      bump();
      Alert.alert('Requested', 'The host will confirm your seat.');
      router.push('/ride');
    } catch (e) {
      setError(messageFrom(e));
    } finally {
      setBusy(false);
    }
  };

  return (
    <ScreenScaffold tone="map">
      <View style={{ flex: 1 }}>
        <OsmMap
          flex
          points={
            ride
              ? [
                  { latitude: ride.originLat, longitude: ride.originLng, title: ride.originLabel, color: colors.brandBlue },
                  { latitude: ride.destinationLat, longitude: ride.destinationLng, title: ride.destinationLabel, color: colors.brandOrange },
                ]
              : []
          }
          route={ride?.routeGeometry?.map((p) => ({ latitude: p[0], longitude: p[1] }))}
        />
        <ScrollView style={sheet} contentContainerStyle={{ padding: 20, paddingBottom: 40 }}>
          {error ? <ErrorBanner message={error} /> : null}
          {ride ? (
            <>
              <HostTrust name={ride.poster?.displayName ?? 'Ride Host'} verified={ride.poster?.employeeVerified} />
              <Text style={{ fontFamily: fonts.display, fontSize: 22, color: colors.ink, marginTop: 16 }}>
                {ride.originLabel} → {ride.destinationLabel}
              </Text>
              <Text style={{ fontFamily: fonts.body, color: colors.inkMuted, marginTop: 6 }}>
                {format(ride.departAt, 'h:mm a')} → {arrival ? format(arrival, 'h:mm a') : ''}
              </Text>
              <Text style={{ fontFamily: fonts.bodySemi, color: colors.ink, marginTop: 10 }}>
                {ride.availableSeats} seats available
              </Text>
              <Text style={{ fontFamily: fonts.displaySemi, color: colors.brandOrange, fontSize: 20, marginTop: 4 }}>
                Suggested contribution ₹{Math.round(ride.pricePerSeat)}
              </Text>
              <View style={{ marginTop: 10 }}>
                <MatchBadge percent={percent} />
              </View>
              {ride.detourKm != null ? (
                <Text style={{ fontFamily: fonts.body, color: colors.inkMuted, marginTop: 6 }}>
                  Host detour +{ride.detourKm.toFixed(1)} km · pickup stays approximate
                </Text>
              ) : null}

              <View style={{ height: 16 }} />
              {!isOwner ? <PrimaryButton label="Request to Join" loading={busy} onPress={requestJoin} /> : null}
              <View style={{ height: 10 }} />
              <View style={{ flexDirection: 'row', gap: 10 }}>
                <View style={{ flex: 1 }}>
                  <OutlineButton label="Route match" onPress={() => router.push(`/ride/match/${ride.id}`)} />
                </View>
                <View style={{ flex: 1 }}>
                  <OutlineButton
                    label="Message"
                    onPress={async () => {
                      if (isOwner && bookings[0]) {
                        const conv = await chatRepo.open({ bookingId: bookings[0].id });
                        router.push(`/chat/${conv.id}`);
                        return;
                      }
                      router.push('/chat');
                    }}
                  />
                </View>
              </View>
              <Pressable onPress={() => router.push('/more/safety')} style={{ paddingVertical: 14, alignItems: 'center' }}>
                <Text style={{ fontFamily: fonts.bodySemi, color: colors.inkMuted }}>Safety</Text>
              </Pressable>
              <OutlineButton
                label="Share on WhatsApp"
                onPress={async () => {
                  const share = await rideRepo.share(id);
                  await shareTextToWhatsApp(String(share.text ?? share.message ?? ''));
                }}
              />

              {isOwner ? (
                <View style={{ marginTop: 20 }}>
                  <PrimaryButton label="Find co-riders" onPress={() => router.push(`/ride/co-riders/${id}`)} />
                  {ride.status === 'open' ? (
                    <View style={{ marginTop: 10 }}>
                      <OutlineButton
                        danger
                        label="Cancel ride"
                        onPress={() =>
                          Alert.alert('Cancel this ride?', 'Co-riders will be notified.', [
                            { text: 'Keep' },
                            {
                              text: 'Cancel ride',
                              style: 'destructive',
                              onPress: async () => {
                                await rideRepo.cancelRide(id);
                                bump();
                                router.back();
                              },
                            },
                          ])
                        }
                      />
                    </View>
                  ) : null}
                  {bookings.map((b) => (
                    <View key={b.id} style={booking}>
                      <Text style={{ fontFamily: fonts.bodySemi, color: colors.ink }}>
                        {b.status} · {b.seatsRequested} seat · ₹{Math.round(b.amount)}
                      </Text>
                      {b.status === 'requested' ? (
                        <View style={{ flexDirection: 'row', gap: 8, marginTop: 10 }}>
                          <View style={{ flex: 1 }}>
                            <PrimaryButton
                              label="Accept"
                              onPress={async () => {
                                await rideRepo.decideBooking(b.id, true);
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
                                await rideRepo.decideBooking(b.id, false);
                                await load();
                              }}
                            />
                          </View>
                        </View>
                      ) : null}
                    </View>
                  ))}
                </View>
              ) : null}
            </>
          ) : null}
        </ScrollView>
      </View>
    </ScreenScaffold>
  );
}

const sheet = {
  maxHeight: '54%' as const,
  backgroundColor: colors.surfaceElevated,
  borderTopLeftRadius: 24,
  borderTopRightRadius: 24,
};
const booking = {
  marginTop: 12,
  padding: 14,
  borderRadius: 16,
  borderWidth: 1,
  borderColor: colors.line,
};
