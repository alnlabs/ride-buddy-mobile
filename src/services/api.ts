import axios, { AxiosError, AxiosInstance, InternalAxiosRequestConfig } from 'axios';

import { Env } from '@/src/config/env';
import { appStorage } from '@/src/services/storage';

export const storageKeys = {
  accessToken: 'access_token',
  refreshToken: 'refresh_token',
  userId: 'user_id',
  phone: 'phone',
  displayName: 'display_name',
} as const;

type SessionListener = () => void;
const sessionListeners = new Set<SessionListener>();

export function onSessionExpired(listener: SessionListener): () => void {
  sessionListeners.add(listener);
  return () => sessionListeners.delete(listener);
}

function notifySessionExpired() {
  sessionListeners.forEach((l) => l());
}

let refreshing = false;

async function tryRefresh(): Promise<boolean> {
  if (refreshing) return false;
  refreshing = true;
  try {
    const refresh = await appStorage.getItem(storageKeys.refreshToken);
    if (!refresh) return false;
    const res = await axios.post(`${Env.apiBaseUrl}/auth/refresh`, { refreshToken: refresh });
    await appStorage.setItem(storageKeys.accessToken, res.data.accessToken);
    await appStorage.setItem(storageKeys.refreshToken, res.data.refreshToken);
    return true;
  } catch {
    await appStorage.deleteItem(storageKeys.accessToken);
    await appStorage.deleteItem(storageKeys.refreshToken);
    return false;
  } finally {
    refreshing = false;
  }
}

export const api: AxiosInstance = axios.create({
  baseURL: Env.apiBaseUrl,
  timeout: 15000,
  headers: { 'Content-Type': 'application/json' },
});

api.interceptors.request.use(async (config: InternalAxiosRequestConfig) => {
  const token = await appStorage.getItem(storageKeys.accessToken);
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

api.interceptors.response.use(
  (res) => res,
  async (error: AxiosError) => {
    const code = error.response?.status;
    const path = error.config?.url ?? '';
    if ((code === 401 || code === 403) && !path.includes('/auth/')) {
      const refreshed = await tryRefresh();
      if (refreshed && error.config) {
        const token = await appStorage.getItem(storageKeys.accessToken);
        error.config.headers.Authorization = `Bearer ${token}`;
        return api.request(error.config);
      }
      notifySessionExpired();
    }
    return Promise.reject(error);
  },
);

export function messageFrom(e: unknown): string {
  if (axios.isAxiosError(e)) {
    if (e.code === 'ECONNABORTED' || e.message.includes('timeout')) {
      return `Could not reach the server at ${Env.apiBaseUrl}. Check that the backend is running and EXPO_PUBLIC_API_BASE_URL uses your computer's LAN IP (not the router). Phone and computer must be on the same Wi‑Fi.`;
    }
    if (e.message.includes('Network Error') || e.code === 'ERR_NETWORK') {
      return `Connection failed (${Env.apiBaseUrl}). Start the backend and confirm the IP in .env.`;
    }
    const code = e.response?.status;
    if (code === 401 || code === 403) return 'Session expired — please sign in again';
    const data = e.response?.data as Record<string, unknown> | undefined;
    if (data) {
      if (data.detail) return String(data.detail);
      if (data.title && data.title !== 'Bad Request') return String(data.title);
      if (data.message) return String(data.message);
    }
    return e.message || 'Network error';
  }
  return e instanceof Error ? e.message : String(e);
}
