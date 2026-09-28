import { router } from 'expo-router';
import { format } from 'date-fns';
import { RefreshControl, ScrollView, Text, View } from 'react-native';

import { Avatar, EmptyState, ErrorView, LoadingSkeleton, SkyScaffold, SoftPanel } from '@/src/components/ui/kit';
import { messageFrom } from '@/src/store/auth';
import { useChatInbox } from '@/src/store/query';
import { colors, fonts } from '@/src/theme/colors';

export default function ChatInboxScreen() {
  const inbox = useChatInbox();
  if (inbox.isLoading) return <SkyScaffold><LoadingSkeleton /></SkyScaffold>;
  if (inbox.isError) return <SkyScaffold><ErrorView message={messageFrom(inbox.error)} onRetry={() => inbox.refetch()} /></SkyScaffold>;
  const list = inbox.data ?? [];

  return (
    <SkyScaffold>
      <ScrollView contentContainerStyle={{ padding: 20, gap: 10 }} refreshControl={<RefreshControl refreshing={inbox.isFetching} onRefresh={() => inbox.refetch()} />}>
        {list.length === 0 ? (
          <SoftPanel>
            <EmptyState title="No chats yet" subtitle="Message a host or co-rider after you request a seat or send an offer" icon="chat-bubble-outline" />
          </SoftPanel>
        ) : (
          list.map((c) => (
            <SoftPanel key={c.id} onPress={() => router.push(`/chat/${c.id}`)}>
              <View style={{ flexDirection: 'row', gap: 12 }}>
                <Avatar name={c.peer.displayName} size={40} />
                <View style={{ flex: 1 }}>
                  <View style={{ flexDirection: 'row', justifyContent: 'space-between' }}>
                    <Text style={{ fontFamily: fonts.bodyBold }}>{c.peer.displayName}</Text>
                    <Text style={{ color: colors.brandOrange, fontFamily: fonts.bodyBold, fontSize: 11 }}>
                      {c.myRole === 'host' ? 'Co-rider' : 'Host'}
                    </Text>
                  </View>
                  <Text style={{ color: colors.inkMuted }} numberOfLines={1}>
                    {c.rideOriginLabel ?? 'From'} → {c.rideDestinationLabel ?? 'To'}
                  </Text>
                  {c.lastMessagePreview ? (
                    <Text style={{ fontFamily: c.unreadCount ? fonts.bodyBold : fonts.body }} numberOfLines={2}>
                      {c.lastMessagePreview}
                    </Text>
                  ) : null}
                  {c.lastMessageAt ? (
                    <Text style={{ color: colors.inkMuted, fontSize: 12 }}>{format(c.lastMessageAt, 'MMM d, h:mm a')}</Text>
                  ) : null}
                </View>
                {c.unreadCount > 0 ? (
                  <View style={{ backgroundColor: colors.brandOrange, borderRadius: 999, minWidth: 22, paddingHorizontal: 6, height: 22, justifyContent: 'center' }}>
                    <Text style={{ color: '#fff', fontFamily: fonts.bodyBold, fontSize: 11, textAlign: 'center' }}>
                      {c.unreadCount > 99 ? '99+' : c.unreadCount}
                    </Text>
                  </View>
                ) : null}
              </View>
            </SoftPanel>
          ))
        )}
      </ScrollView>
    </SkyScaffold>
  );
}
