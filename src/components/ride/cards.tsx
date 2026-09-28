import { MaterialIcons } from '@expo/vector-icons';
import { format } from 'date-fns';
import { Pressable, StyleSheet, Text, View } from 'react-native';

import { FareChip, SoftPanel } from '@/src/components/ui/kit';
import {
  NeedInboxItem,
  PosterCard,
  Ride,
  RideRequest,
  destinationTitle,
  originTitle,
  workLine,
} from '@/src/models/types';
import { colors, fonts } from '@/src/theme/colors';

function PosterIdentity({ poster, role }: { poster: PosterCard; role: string }) {
  return (
    <View style={styles.poster}>
      <View style={styles.avatar}>
        <Text style={styles.avatarText}>{poster.displayName[0]?.toUpperCase() ?? '?'}</Text>
      </View>
      <View style={{ flex: 1 }}>
        <View style={styles.row}>
          <Text style={styles.name}>{poster.displayName}</Text>
          {poster.employeeVerified ? <MaterialIcons name="verified" size={16} color={colors.brandBlue} /> : null}
          <View style={styles.role}>
            <Text style={styles.roleText}>{role}</Text>
          </View>
        </View>
        {workLine(poster.jobRole, poster.company) ? (
          <Text style={styles.sub}>{workLine(poster.jobRole, poster.company)}</Text>
        ) : null}
        {poster.topInterests.length ? (
          <Text style={styles.sub} numberOfLines={1}>{poster.topInterests.slice(0, 5).join(' · ')}</Text>
        ) : null}
      </View>
    </View>
  );
}

function RouteStrip({ from, to, accent }: { from: string; to: string; accent: string }) {
  return (
    <View style={{ gap: 6 }}>
      <Text style={styles.route}><Text style={{ color: accent }}>From  </Text>{from}</Text>
      <Text style={styles.route}><Text style={{ color: accent }}>To  </Text>{to}</Text>
    </View>
  );
}

export function RidePostCard({
  ride,
  onPress,
  isOwner = false,
}: {
  ride: Ride;
  onPress?: () => void;
  isOwner?: boolean;
}) {
  return (
    <SoftPanel onPress={onPress}>
      <View style={styles.space}>
        <View style={styles.tagOrange}>
          <Text style={styles.tagOrangeText}>{isOwner ? 'Offering' : 'Open seat'}</Text>
        </View>
        <FareChip pricePerSeat={ride.pricePerSeat} compact />
      </View>
      {ride.poster ? <PosterIdentity poster={ride.poster} role="Host" /> : null}
      <RouteStrip
        from={originTitle(ride, isOwner)}
        to={destinationTitle(ride, isOwner)}
        accent={colors.brandOrange}
      />
      <Text style={styles.meta}>
        {format(ride.departAt, 'MMM d, h:mm a')} · {ride.availableSeats} seat{ride.availableSeats === 1 ? '' : 's'}
        {ride.comfortRide ? ' · Comfort' : ''}
      </Text>
    </SoftPanel>
  );
}

export function NeedPostCard({
  need,
  onPress,
  isOwner = false,
}: {
  need: RideRequest;
  onPress?: () => void;
  isOwner?: boolean;
}) {
  return (
    <SoftPanel onPress={onPress}>
      <View style={styles.tagBlue}>
        <Text style={styles.tagBlueText}>Need a seat</Text>
      </View>
      {need.poster ? <PosterIdentity poster={need.poster} role="Co-rider" /> : null}
      <RouteStrip
        from={need.originPrivateLabel && isOwner ? need.originPrivateLabel : need.originLabel}
        to={need.destinationPrivateLabel && isOwner ? need.destinationPrivateLabel : need.destinationLabel}
        accent={colors.brandBlue}
      />
      <Text style={styles.meta}>
        {format(need.departAt, 'MMM d, h:mm a')} · {need.seatsNeeded} seat{need.seatsNeeded === 1 ? '' : 's'}
        {need.comfortPreferred ? ' · Comfort preferred' : ''}
      </Text>
    </SoftPanel>
  );
}

export function InboxNeedCard({
  item,
  offering,
  onOffer,
  onPress,
}: {
  item: NeedInboxItem;
  offering?: boolean;
  onOffer?: () => void;
  onPress?: () => void;
}) {
  return (
    <View style={{ gap: 8 }}>
      <NeedPostCard need={item.request} onPress={onPress} />
      <View style={styles.space}>
        <Text style={styles.meta}>
          {item.detourKm.toFixed(1)} km detour{item.alreadyOffered ? ' · offered' : ''}
        </Text>
        {onOffer && !item.alreadyOffered ? (
          <Pressable onPress={offering ? undefined : onOffer}>
            <Text style={styles.offer}>{offering ? 'Sending…' : 'Offer seat'}</Text>
          </Pressable>
        ) : null}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  space: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  tagOrange: { backgroundColor: `${colors.brandOrange}1F`, borderRadius: 8, paddingHorizontal: 8, paddingVertical: 4 },
  tagOrangeText: { color: colors.brandOrange, fontFamily: fonts.bodyBold, fontSize: 12 },
  tagBlue: { alignSelf: 'flex-start', backgroundColor: `${colors.brandBlue}1F`, borderRadius: 8, paddingHorizontal: 8, paddingVertical: 4, marginBottom: 8 },
  tagBlueText: { color: colors.brandBlue, fontFamily: fonts.bodyBold, fontSize: 12 },
  poster: { flexDirection: 'row', gap: 10, marginVertical: 10 },
  avatar: { width: 36, height: 36, borderRadius: 18, backgroundColor: `${colors.brandBlue}1F`, alignItems: 'center', justifyContent: 'center' },
  avatarText: { color: colors.brandBlue, fontFamily: fonts.bodyBold },
  row: { flexDirection: 'row', alignItems: 'center', gap: 6 },
  name: { fontFamily: fonts.bodyBold, color: colors.ink },
  role: { backgroundColor: `${colors.brandOrange}24`, borderRadius: 999, paddingHorizontal: 7, paddingVertical: 2 },
  roleText: { color: colors.brandOrange, fontSize: 11, fontFamily: fonts.bodyBold },
  sub: { fontFamily: fonts.body, color: colors.inkMuted, fontSize: 12 },
  route: { fontFamily: fonts.bodySemi, color: colors.ink, fontSize: 15 },
  meta: { fontFamily: fonts.body, color: colors.inkMuted, fontSize: 13, marginTop: 8 },
  offer: { color: colors.brandOrange, fontFamily: fonts.bodyBold },
});
