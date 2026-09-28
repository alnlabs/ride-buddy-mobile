import { useLocalSearchParams, useNavigation } from 'expo-router';
import { format } from 'date-fns';
import { useEffect, useRef, useState } from 'react';
import { ActivityIndicator, Pressable, ScrollView, Text, TextInput, View } from 'react-native';

import { SkyScaffold } from '@/src/components/ui/kit';
import { ChatConversation, ChatMessage } from '@/src/models/types';
import { chatRepo } from '@/src/services/chatRepository';
import { onChatMessage } from '@/src/services/chatSocket';
import { useAuth } from '@/src/store/auth';
import { useInvalidateAll } from '@/src/store/query';
import { colors, fonts } from '@/src/theme/colors';

export default function ChatThreadScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const navigation = useNavigation();
  const { userId } = useAuth();
  const invalidate = useInvalidateAll();
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [conversation, setConversation] = useState<ChatConversation | null>(null);
  const [text, setText] = useState('');
  const [sending, setSending] = useState(false);
  const [loading, setLoading] = useState(true);
  const scroll = useRef<ScrollView>(null);

  const load = async () => {
    if (!id) return;
    setLoading(true);
    try {
      const inbox = await chatRepo.conversations();
      const conv = inbox.find((c) => c.id === id) ?? null;
      setConversation(conv);
      navigation.setOptions({ title: conv?.peer.displayName ?? 'Chat' });
      const page = await chatRepo.messages(id);
      setMessages([...page].reverse());
      invalidate();
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    void load();
  }, [id]);

  useEffect(() => {
    return onChatMessage((msg) => {
      if (msg.conversationId !== id) return;
      setMessages((cur) => (cur.some((m) => m.id === msg.id) ? cur : [...cur, msg]));
    });
  }, [id]);

  const send = async () => {
    const body = text.trim();
    if (!body || !id) return;
    setSending(true);
    try {
      const msg = await chatRepo.send(id, body);
      setMessages((cur) => (cur.some((m) => m.id === msg.id) ? cur : [...cur, msg]));
      setText('');
      invalidate();
    } finally {
      setSending(false);
    }
  };

  return (
    <SkyScaffold>
      {conversation ? (
        <View style={{ paddingHorizontal: 16, paddingVertical: 8, backgroundColor: colors.surfaceElevated }}>
          <Text style={{ color: colors.inkMuted }} numberOfLines={1}>
            {conversation.rideOriginLabel ?? 'From'} → {conversation.rideDestinationLabel ?? 'To'}
          </Text>
        </View>
      ) : null}
      {loading ? <ActivityIndicator style={{ marginTop: 24 }} color={colors.brandBlue} /> : (
        <ScrollView
          ref={scroll}
          onContentSizeChange={() => scroll.current?.scrollToEnd({ animated: true })}
          contentContainerStyle={{ padding: 16, gap: 8 }}>
          {messages.length === 0 ? (
            <Text style={{ textAlign: 'center', color: colors.inkMuted }}>
              {conversation?.canSend === false ? 'Chat history (messaging closed)' : 'Say hello — keep it about the commute'}
            </Text>
          ) : (
            messages.map((m) => {
              const mine = m.senderId === userId;
              return (
                <View key={m.id} style={{ alignItems: mine ? 'flex-end' : 'flex-start' }}>
                  <View style={{
                    maxWidth: '78%',
                    padding: 10,
                    borderRadius: 14,
                    borderWidth: 1,
                    borderColor: colors.line,
                    backgroundColor: mine ? `${colors.brandBlue}24` : colors.surfaceElevated,
                  }}>
                    <Text style={{ fontFamily: fonts.body, color: colors.ink }}>{m.body}</Text>
                    <Text style={{ color: colors.inkMuted, fontSize: 11, marginTop: 4 }}>{format(m.createdAt, 'h:mm a')}</Text>
                  </View>
                </View>
              );
            })
          )}
        </ScrollView>
      )}
      <View style={{ flexDirection: 'row', gap: 8, padding: 12, alignItems: 'center' }}>
        <TextInput
          value={text}
          onChangeText={setText}
          editable={conversation?.canSend !== false && !sending}
          placeholder={conversation?.canSend === false ? 'Chat closed' : 'Message…'}
          placeholderTextColor={colors.inkMuted}
          style={{
            flex: 1,
            backgroundColor: colors.surfaceElevated,
            borderWidth: 1,
            borderColor: colors.line,
            borderRadius: 14,
            paddingHorizontal: 14,
            paddingVertical: 12,
            fontFamily: fonts.body,
          }}
          onSubmitEditing={send}
        />
        <Pressable
          onPress={send}
          disabled={sending || conversation?.canSend === false}
          style={{ width: 44, height: 44, borderRadius: 14, backgroundColor: colors.brandBlue, alignItems: 'center', justifyContent: 'center' }}>
          {sending ? <ActivityIndicator color="#fff" /> : <Text style={{ color: '#fff', fontFamily: fonts.bodyBold }}>→</Text>}
        </Pressable>
      </View>
    </SkyScaffold>
  );
}
