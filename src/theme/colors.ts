import { Platform } from 'react-native';

export const colors = {
  brandBlue: '#1D4ED8',
  brandOrange: '#EA580C',
  ink: '#0F172A',
  inkMuted: '#64748B',
  surface: '#F8FAFC',
  surfaceElevated: '#FFFFFF',
  skyTop: '#E8F1FF',
  skyMid: '#F5F8FC',
  line: '#E2E8F0',
  success: '#059669',
  danger: '#DC2626',
  matchGood: '#059669',
  matchFair: '#D97706',
} as const;

const web = Platform.OS === 'web';

/**
 * RN-web + webfonts eats spaces and doubles the last letter.
 * Web uses the system UI font only. Native keeps Outfit / DM Sans.
 */
export const fonts = {
  display: web ? 'system-ui' : 'Outfit_700Bold',
  displaySemi: web ? 'system-ui' : 'Outfit_600SemiBold',
  displayExtra: web ? 'system-ui' : 'Outfit_800ExtraBold',
  body: web ? 'system-ui' : 'DMSans_400Regular',
  bodyMedium: web ? 'system-ui' : 'DMSans_500Medium',
  bodySemi: web ? 'system-ui' : 'DMSans_600SemiBold',
  bodyBold: web ? 'system-ui' : 'DMSans_700Bold',
} as const;

export const weights = {
  display: web ? '700' : undefined,
  displaySemi: web ? '600' : undefined,
  displayExtra: web ? '800' : undefined,
  body: web ? '400' : undefined,
  bodyMedium: web ? '500' : undefined,
  bodySemi: web ? '600' : undefined,
  bodyBold: web ? '700' : undefined,
} as const;
