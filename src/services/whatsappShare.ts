import { Platform, Share } from 'react-native';
import * as Linking from 'expo-linking';
import * as Sharing from 'expo-sharing';

export async function shareTextToWhatsApp(text: string): Promise<void> {
  const trimmed = text.trim();
  if (!trimmed) return;

  if (Platform.OS === 'ios') {
    const appUri = `whatsapp://send?text=${encodeURIComponent(trimmed)}`;
    try {
      const can = await Linking.canOpenURL(appUri);
      if (can) {
        await Linking.openURL(appUri);
        return;
      }
    } catch {
      /* fall through */
    }
  }

  try {
    await Share.share({ message: trimmed });
    return;
  } catch {
    /* fall through */
  }

  if (await Sharing.isAvailableAsync()) {
    await Sharing.shareAsync(`data:text/plain,${encodeURIComponent(trimmed)}`);
  }
}
