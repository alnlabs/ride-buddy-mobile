import AsyncStorage from '@react-native-async-storage/async-storage';
import { Platform } from 'react-native';

type KeyValueStore = {
  getItem: (key: string) => Promise<string | null>;
  setItem: (key: string, value: string) => Promise<void>;
  deleteItem: (key: string) => Promise<void>;
};

const asyncStore: KeyValueStore = {
  getItem: (key) => AsyncStorage.getItem(key),
  setItem: (key, value) => AsyncStorage.setItem(key, value),
  deleteItem: (key) => AsyncStorage.removeItem(key),
};

let store: KeyValueStore | null = Platform.OS === 'web' ? asyncStore : null;

async function resolveStore(): Promise<KeyValueStore> {
  if (store) return store;
  try {
    const SecureStore = await import('expo-secure-store');
    const available = await SecureStore.isAvailableAsync();
    if (!available || typeof SecureStore.getItemAsync !== 'function') {
      store = asyncStore;
      return store;
    }
    // Probe the native binding. Expo web (and some Expo Go builds) export an
    // empty default, so getItemAsync throws "getValueWithKeyAsync is not a function".
    await SecureStore.getItemAsync('ridebuddy_secure_probe');
    store = {
      getItem: (key) => SecureStore.getItemAsync(key),
      setItem: (key, value) => SecureStore.setItemAsync(key, value),
      deleteItem: (key) => SecureStore.deleteItemAsync(key),
    };
  } catch {
    store = asyncStore;
  }
  return store;
}

export const appStorage = {
  getItem: async (key: string) => (await resolveStore()).getItem(key),
  setItem: async (key: string, value: string) => (await resolveStore()).setItem(key, value),
  deleteItem: async (key: string) => (await resolveStore()).deleteItem(key),
};
