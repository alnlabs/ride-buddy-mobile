import { createContext, useContext, useEffect, useMemo, useState, type ReactNode } from 'react';

import { api, messageFrom, onSessionExpired, storageKeys } from '@/src/services/api';
import { connectChatSocket, disconnectChatSocket } from '@/src/services/chatSocket';
import { appStorage } from '@/src/services/storage';

export type AuthState = {
  token: string | null;
  userId: string | null;
  phone: string | null;
  displayName: string | null;
  initializing: boolean;
  loading: boolean;
};

type AuthContextValue = AuthState & {
  isAuthenticated: boolean;
  requestOtp: (phone: string) => Promise<boolean>;
  verifyOtp: (phone: string, code: string, displayName?: string) => Promise<void>;
  logout: () => Promise<void>;
};

const AuthContext = createContext<AuthContextValue | null>(null);

const empty: AuthState = {
  token: null,
  userId: null,
  phone: null,
  displayName: null,
  initializing: true,
  loading: false,
};

async function clearStorage() {
  await Promise.all(Object.values(storageKeys).map((k) => appStorage.deleteItem(k)));
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [state, setState] = useState<AuthState>(empty);

  useEffect(() => {
    (async () => {
      try {
        const [token, userId, phone, displayName] = await Promise.all([
          appStorage.getItem(storageKeys.accessToken),
          appStorage.getItem(storageKeys.userId),
          appStorage.getItem(storageKeys.phone),
          appStorage.getItem(storageKeys.displayName),
        ]);
        if (token) {
          setState({ token, userId, phone, displayName, initializing: false, loading: false });
        } else {
          setState({ ...empty, initializing: false });
        }
      } catch {
        setState({ ...empty, initializing: false });
      }
    })();
  }, []);

  useEffect(() => {
    return onSessionExpired(async () => {
      await clearStorage();
      await disconnectChatSocket();
      setState({ ...empty, initializing: false });
    });
  }, []);

  useEffect(() => {
    if (state.token) {
      void connectChatSocket();
    } else {
      void disconnectChatSocket();
    }
  }, [state.token]);

  const value = useMemo<AuthContextValue>(
    () => ({
      ...state,
      isAuthenticated: Boolean(state.token),
      requestOtp: async (phone: string) => {
        const res = await api.post('/auth/otp/request', { phone });
        return res.data?.needsDisplayName === true;
      },
      verifyOtp: async (phone: string, code: string, displayName?: string) => {
        const res = await api.post('/auth/otp/verify', {
          phone,
          code,
          ...(displayName ? { displayName } : {}),
        });
        const data = res.data as Record<string, string>;
        await appStorage.setItem(storageKeys.accessToken, data.accessToken);
        await appStorage.setItem(storageKeys.refreshToken, data.refreshToken);
        await appStorage.setItem(storageKeys.userId, data.userId);
        await appStorage.setItem(storageKeys.phone, data.phone);
        await appStorage.setItem(storageKeys.displayName, data.displayName ?? '');
        setState({
          token: data.accessToken,
          userId: data.userId,
          phone: data.phone,
          displayName: data.displayName,
          initializing: false,
          loading: false,
        });
      },
      logout: async () => {
        await clearStorage();
        await disconnectChatSocket();
        setState({ ...empty, initializing: false });
      },
    }),
    [state],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used inside AuthProvider');
  return ctx;
}

export { messageFrom };
