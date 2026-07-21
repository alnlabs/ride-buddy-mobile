import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8080/api/v1';

  /// Origin for WebSocket (strip `/api/v1`, keep scheme/host/port).
  static String get apiOrigin {
    final uri = Uri.parse(apiBaseUrl);
    var segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.length >= 2 && segments[segments.length - 2] == 'api' && segments.last == 'v1') {
      segments = segments.sublist(0, segments.length - 2);
    }
    return uri.replace(pathSegments: segments).toString().replaceAll(RegExp(r'/$'), '');
  }

  /// Native STOMP endpoint (`ws://host:8080/ws-native`).
  static String wsNativeUrl({required String accessToken}) {
    final origin = Uri.parse(apiOrigin);
    final scheme = origin.scheme == 'https' ? 'wss' : 'ws';
    final segs = [
      ...origin.pathSegments.where((s) => s.isNotEmpty),
      'ws-native',
    ];
    return Uri(
      scheme: scheme,
      host: origin.host,
      port: origin.hasPort ? origin.port : null,
      pathSegments: segs,
      queryParameters: {'access_token': accessToken},
    ).toString();
  }
}
