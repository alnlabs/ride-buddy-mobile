import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shares [text] into WhatsApp with the full message body.
///
/// Do **not** use `whatsapp://send?text=` / `api.whatsapp.com` as the primary
/// path on Android — Intent `VIEW` query strings are truncated, so WhatsApp
/// often opens with only the trailing http(s) link.
Future<void> shareTextToWhatsApp(String text) async {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return;

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    for (final package in const ['com.whatsapp', 'com.whatsapp.w4b']) {
      try {
        final intent = AndroidIntent(
          action: 'android.intent.action.SEND',
          package: package,
          type: 'text/plain',
          arguments: <String, dynamic>{
            'android.intent.extra.TEXT': trimmed,
          },
        );
        await intent.launch();
        return;
      } catch (_) {
        // Try next package / fall through.
      }
    }
  }

  // iOS / other: short deep link can work; still avoid https api URL.
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
    final appUri = Uri(
      scheme: 'whatsapp',
      host: 'send',
      queryParameters: {'text': trimmed},
    );
    try {
      if (await canLaunchUrl(appUri) &&
          await launchUrl(appUri, mode: LaunchMode.externalApplication)) {
        return;
      }
    } catch (_) {}
  }

  await SharePlus.instance.share(ShareParams(text: trimmed));
}
