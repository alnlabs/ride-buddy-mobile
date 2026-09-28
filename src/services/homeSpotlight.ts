import AsyncStorage from '@react-native-async-storage/async-storage';
import { format } from 'date-fns';

import { spotlightById, spotlightQuotes, spotlightTips } from '@/src/data/homeSpotlights';
import { HomeSpotlight } from '@/src/models/types';

const enabledKey = 'app_tips_enabled';
const spotlightIdKey = 'spotlight_id';
const spotlightDateKey = 'spotlight_date';
const popupDateKey = 'spotlight_popup_date';
const cardDismissedDateKey = 'spotlight_card_dismissed_date';
const lastIdKey = 'spotlight_last_id';

const today = () => format(new Date(), 'yyyy-MM-dd');

function pickNew(lastId?: string | null): HomeSpotlight {
  const wantQuote = Math.random() < 0.25;
  let pool = wantQuote ? [...spotlightQuotes] : [...spotlightTips];
  if (lastId && pool.length > 1) pool = pool.filter((s) => s.id !== lastId);
  if (!pool.length) pool = [...spotlightTips];
  return pool[Math.floor(Math.random() * pool.length)];
}

export const homeSpotlight = {
  tipsEnabled: async () => (await AsyncStorage.getItem(enabledKey)) !== 'false',
  setTipsEnabled: (enabled: boolean) => AsyncStorage.setItem(enabledKey, String(enabled)),

  todaySpotlight: async (): Promise<HomeSpotlight | null> => {
    if (!(await homeSpotlight.tipsEnabled())) return null;
    const day = today();
    const storedDate = await AsyncStorage.getItem(spotlightDateKey);
    const storedId = await AsyncStorage.getItem(spotlightIdKey);
    if (storedDate === day && storedId) {
      const cached = spotlightById(storedId);
      if (cached) return cached;
    }
    const lastId = await AsyncStorage.getItem(lastIdKey);
    const pick = pickNew(lastId);
    await AsyncStorage.setItem(spotlightIdKey, pick.id);
    await AsyncStorage.setItem(spotlightDateKey, day);
    await AsyncStorage.setItem(lastIdKey, pick.id);
    if (storedDate !== day) {
      await AsyncStorage.removeItem(popupDateKey);
      await AsyncStorage.removeItem(cardDismissedDateKey);
    }
    return pick;
  },

  shouldShowPopup: async () => {
    if (!(await homeSpotlight.tipsEnabled())) return false;
    return (await AsyncStorage.getItem(popupDateKey)) !== today();
  },
  markPopupShown: () => AsyncStorage.setItem(popupDateKey, today()),
  shouldShowCard: async () => {
    if (!(await homeSpotlight.tipsEnabled())) return false;
    return (await AsyncStorage.getItem(cardDismissedDateKey)) !== today();
  },
  dismissCard: () => AsyncStorage.setItem(cardDismissedDateKey, today()),
  allTips: () => spotlightTips,
  allQuotes: () => spotlightQuotes,
  tipsForCategory: (category: string) => spotlightTips.filter((t) => t.category === category),
};
