import { Client, IMessage } from '@stomp/stompjs';

import { Env } from '@/src/config/env';
import { ChatMessage, parseMessage } from '@/src/models/types';
import { storageKeys } from '@/src/services/api';
import { appStorage } from '@/src/services/storage';

import 'text-encoding';

type Listener = (msg: ChatMessage) => void;
const listeners = new Set<Listener>();

let client: Client | null = null;
let connecting = false;

export function onChatMessage(listener: Listener): () => void {
  listeners.add(listener);
  return () => listeners.delete(listener);
}

export async function connectChatSocket(): Promise<void> {
  if (connecting || client?.connected) return;
  const token = await appStorage.getItem(storageKeys.accessToken);
  if (!token) return;
  connecting = true;
  try {
    await disconnectChatSocket();
    const next = new Client({
      brokerURL: Env.wsNativeUrl(token),
      reconnectDelay: 4000,
      connectionTimeout: 12000,
      onConnect: () => {
        next.subscribe('/user/queue/chat', (frame: IMessage) => {
          if (!frame.body) return;
          try {
            const msg = parseMessage(JSON.parse(frame.body) as Record<string, unknown>);
            listeners.forEach((l) => l(msg));
          } catch {
            /* ignore malformed frames */
          }
        });
      },
    });
    client = next;
    next.activate();
  } finally {
    connecting = false;
  }
}

export async function disconnectChatSocket(): Promise<void> {
  const current = client;
  client = null;
  try {
    await current?.deactivate();
  } catch {
    /* ignore */
  }
}
