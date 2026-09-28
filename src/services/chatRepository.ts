import { ChatConversation, ChatMessage, parseConversation, parseMessage } from '@/src/models/types';
import { api } from '@/src/services/api';

export const chatRepo = {
  conversations: async (): Promise<ChatConversation[]> => {
    const list = ((await api.get('/chat/conversations')).data as unknown[]) ?? [];
    return list.map((e) => parseConversation(e as Record<string, unknown>));
  },
  open: async (body: {
    bookingId?: string;
    offerId?: string;
    rideId?: string;
    coRiderId?: string;
  }): Promise<ChatConversation> =>
    parseConversation((await api.post('/chat/conversations/open', body)).data),
  messages: async (conversationId: string, before?: Date, limit = 50): Promise<ChatMessage[]> => {
    const list =
      ((
        await api.get(`/chat/conversations/${conversationId}/messages`, {
          params: { limit, ...(before ? { before: before.toISOString() } : {}) },
        })
      ).data as unknown[]) ?? [];
    return list.map((e) => parseMessage(e as Record<string, unknown>));
  },
  send: async (conversationId: string, body: string): Promise<ChatMessage> =>
    parseMessage((await api.post(`/chat/conversations/${conversationId}/messages`, { body })).data),
};
