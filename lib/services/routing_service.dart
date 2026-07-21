import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:ridebuddy/services/api_client.dart';

final routingServiceProvider = Provider((ref) => RoutingService(ref));

class DriveRoute {
  DriveRoute({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
    this.trafficDelaySeconds = 0,
    this.index = 0,
    this.usesLiveTraffic = false,
    this.viaLabel,
  });

  final List<LatLng> points;
  final double distanceMeters;
  /// Estimated travel time including traffic when [usesLiveTraffic] is true.
  final double durationSeconds;
  /// Extra seconds due to current congestion, if known.
  final double trafficDelaySeconds;
  final int index;
  final bool usesLiveTraffic;
  /// Road / area the route goes through (from Google "via …" description).
  final String? viaLabel;

  String get distanceLabel {
    final km = distanceMeters / 1000;
    return km >= 10 ? '${km.toStringAsFixed(0)} km' : '${km.toStringAsFixed(1)} km';
  }

  String get durationLabel {
    final mins = (durationSeconds / 60).round();
    if (mins < 60) return '$mins min';
    final h = mins ~/ 60;
    final m = mins % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  String get trafficDelayLabel {
    final mins = (trafficDelaySeconds / 60).round();
    if (mins <= 0) return '';
    return '+$mins min traffic';
  }

  /// Chip / list label ranked by arrival time (0 = fastest).
  String get rankLabel {
    if (index == 0) return 'Fastest';
    if (index == 1) return '2nd';
    if (index == 2) return '3rd';
    return 'Alt ${index + 1}';
  }

  String get chipLabel {
    final delay = trafficDelayLabel;
    final live = usesLiveTraffic
        ? (delay.isNotEmpty ? ' · $delay' : ' · live')
        : '';
    return '$rankLabel · $durationLabel · $distanceLabel$live';
  }

  String get footerLabel {
    final via = (viaLabel != null && viaLabel!.trim().isNotEmpty) ? ' · via $viaLabel' : '';
    return '$durationLabel · $distanceLabel$via';
  }

  /// Compact JSON for API: [[lat,lng],...]
  List<List<double>> toJsonCoords() =>
      points.map((p) => <double>[p.latitude, p.longitude]).toList();

  static DriveRoute? fromJsonCoords(
    List? coords, {
    double? distanceMeters,
    double? durationSeconds,
  }) {
    if (coords == null || coords.length < 2) return null;
    final points = <LatLng>[];
    for (final c in coords) {
      if (c is List && c.length >= 2) {
        points.add(LatLng((c[0] as num).toDouble(), (c[1] as num).toDouble()));
      }
    }
    if (points.length < 2) return null;
    return DriveRoute(
      points: points,
      distanceMeters: distanceMeters ?? 0,
      durationSeconds: durationSeconds ?? 0,
    );
  }

  factory DriveRoute.fromApi(Map<String, dynamic> json) {
    final rawPoints = json['points'] as List<dynamic>? ?? const [];
    final points = <LatLng>[];
    for (final c in rawPoints) {
      if (c is List && c.length >= 2) {
        points.add(LatLng((c[0] as num).toDouble(), (c[1] as num).toDouble()));
      }
    }
    final via = json['viaLabel']?.toString().trim();
    return DriveRoute(
      points: points,
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble() ?? 0,
      durationSeconds: (json['durationSeconds'] as num?)?.toDouble() ?? 0,
      trafficDelaySeconds: (json['trafficDelaySeconds'] as num?)?.toDouble() ?? 0,
      usesLiveTraffic: json['usesLiveTraffic'] == true,
      index: (json['index'] as num?)?.toInt() ?? 0,
      viaLabel: (via == null || via.isEmpty) ? null : via,
    );
  }
}

/// Driving routes — backend Google Routes (live traffic) → direct Google → OSRM.
/// Always returns up to **3** alternatives sorted by time-to-arrive (fastest first).
class RoutingService {
  RoutingService(this._ref);

  final Ref _ref;

  Dio get _api => _ref.read(apiClientProvider).dio;

  final Dio _google = Dio(BaseOptions(
    baseUrl: 'https://routes.googleapis.com',
    connectTimeout: const Duration(seconds: 18),
    receiveTimeout: const Duration(seconds: 18),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    validateStatus: (code) => code != null && code >= 200 && code < 500,
  ));

  final Dio _osrm = Dio(BaseOptions(
    baseUrl: 'https://router.project-osrm.org',
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    headers: {
      'User-Agent': 'RideBuddy/1.0 (com.alnlabs.ridebuddy)',
      'Accept': 'application/json',
    },
  ));

  String? get _googleKey {
    final k = dotenv.env['GOOGLE_MAPS_API_KEY']?.trim();
    if (k == null || k.isEmpty || k == 'your_google_maps_key') return null;
    return k;
  }

  /// Top 3 routes by travel time (live traffic when available).
  Future<List<DriveRoute>> routes(LatLng from, LatLng to) async {
    final viaBackend = await _backendRoutes(from, to);
    if (viaBackend.isNotEmpty) return viaBackend;

    final key = _googleKey;
    if (key != null) {
      final live = await _googleRoutes(from, to, key);
      if (live.isNotEmpty) return live;
    }
    return _osrmRoutes(from, to);
  }

  Future<List<DriveRoute>> _backendRoutes(LatLng from, LatLng to) async {
    try {
      final res = await _api.post('/routes/drive', data: {
        'fromLat': from.latitude,
        'fromLng': from.longitude,
        'toLat': to.latitude,
        'toLng': to.longitude,
      });
      final data = res.data;
      if (data is! Map) return [];
      final list = data['routes'] as List<dynamic>? ?? const [];
      final out = <DriveRoute>[];
      for (final raw in list) {
        if (raw is! Map) continue;
        final route = DriveRoute.fromApi(Map<String, dynamic>.from(raw));
        if (route.points.length >= 2) out.add(route);
      }
      return out.isEmpty ? [] : _topThreeByTime(out);
    } catch (_) {
      return [];
    }
  }

  Future<List<DriveRoute>> _googleRoutes(LatLng from, LatLng to, String key) async {
    try {
      final res = await _google.post(
        '/directions/v2:computeRoutes',
        data: {
          'origin': {
            'location': {
              'latLng': {'latitude': from.latitude, 'longitude': from.longitude},
            },
          },
          'destination': {
            'location': {
              'latLng': {'latitude': to.latitude, 'longitude': to.longitude},
            },
          },
          'travelMode': 'DRIVE',
          'routingPreference': 'TRAFFIC_AWARE_OPTIMAL',
          'trafficModel': 'BEST_GUESS',
          'computeAlternativeRoutes': true,
          // Omit departureTime — Google rejects "now" as past; default uses live traffic.
          'languageCode': 'en-IN',
          'regionCode': 'IN',
          'units': 'METRIC',
        },
        options: Options(headers: {
          'X-Goog-Api-Key': key,
          'X-Goog-FieldMask':
              'routes.duration,routes.staticDuration,routes.distanceMeters,'
              'routes.polyline.encodedPolyline,routes.routeLabels,routes.description',
        }),
      );
      if (res.statusCode != 200 || res.data is! Map) return [];
      final routesJson = (res.data as Map)['routes'] as List<dynamic>? ?? [];
      final out = <DriveRoute>[];
      for (final raw in routesJson) {
        if (raw is! Map) continue;
        final encoded = (raw['polyline'] as Map?)?['encodedPolyline']?.toString();
        if (encoded == null || encoded.isEmpty) continue;
        final points = _decodePolyline(encoded);
        if (points.length < 2) continue;
        final durationSec = _parseDurationSeconds(raw['duration']?.toString());
        final staticSec = _parseDurationSeconds(raw['staticDuration']?.toString());
        final delay = (durationSec > 0 && staticSec > 0 && durationSec > staticSec)
            ? durationSec - staticSec
            : 0.0;
        out.add(DriveRoute(
          points: points,
          distanceMeters: (raw['distanceMeters'] as num?)?.toDouble() ?? 0,
          durationSeconds: durationSec > 0 ? durationSec : staticSec,
          trafficDelaySeconds: delay,
          usesLiveTraffic: true,
          viaLabel: _normalizeVia(raw['description']?.toString()),
        ));
      }
      return _topThreeByTime(out);
    } catch (_) {
      return [];
    }
  }

  Future<List<DriveRoute>> _osrmRoutes(LatLng from, LatLng to) async {
    final path =
        '/route/v1/driving/${from.longitude},${from.latitude};${to.longitude},${to.latitude}';
    try {
      final res = await _osrm.get(path, queryParameters: {
        'overview': 'full',
        'geometries': 'geojson',
        'alternatives': 'true',
        'steps': 'false',
      });
      final data = res.data;
      if (data is! Map || data['code'] != 'Ok') return [];
      final routesJson = data['routes'] as List<dynamic>? ?? [];
      final out = <DriveRoute>[];
      for (final raw in routesJson) {
        final r = raw as Map<String, dynamic>;
        final geom = r['geometry'] as Map<String, dynamic>?;
        final coords = geom?['coordinates'] as List<dynamic>? ?? [];
        final points = coords
            .whereType<List>()
            .where((c) => c.length >= 2)
            .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
            .toList();
        if (points.length < 2) continue;
        out.add(DriveRoute(
          points: points,
          distanceMeters: (r['distance'] as num?)?.toDouble() ?? 0,
          durationSeconds: (r['duration'] as num?)?.toDouble() ?? 0,
          usesLiveTraffic: false,
        ));
      }
      return _topThreeByTime(out);
    } catch (_) {
      return [];
    }
  }

  /// Pedestrian path (OSRM foot). Falls back to a straight segment if routing fails.
  Future<DriveRoute> walkRoute(LatLng from, LatLng to) async {
    final straightM = const Distance().as(LengthUnit.Meter, from, to);
    if (straightM < 12) {
      return DriveRoute(points: [from, to], distanceMeters: straightM, durationSeconds: 0);
    }
    try {
      final path =
          '/route/v1/foot/${from.longitude},${from.latitude};${to.longitude},${to.latitude}';
      final res = await _osrm.get(path, queryParameters: {
        'overview': 'full',
        'geometries': 'geojson',
        'alternatives': 'false',
        'steps': 'false',
      });
      final data = res.data;
      if (data is Map && data['code'] == 'Ok') {
        final routesJson = data['routes'] as List<dynamic>? ?? [];
        if (routesJson.isNotEmpty) {
          final r = routesJson.first as Map<String, dynamic>;
          final geom = r['geometry'] as Map<String, dynamic>?;
          final coords = geom?['coordinates'] as List<dynamic>? ?? [];
          final points = coords
              .whereType<List>()
              .where((c) => c.length >= 2)
              .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
              .toList();
          if (points.length >= 2) {
            return DriveRoute(
              points: points,
              distanceMeters: (r['distance'] as num?)?.toDouble() ?? straightM,
              durationSeconds: (r['duration'] as num?)?.toDouble() ?? 0,
            );
          }
        }
      }
    } catch (_) {}
    return DriveRoute(
      points: [from, to],
      distanceMeters: straightM,
      durationSeconds: straightM / 1.4, // ~5 km/h walk
    );
  }

  List<DriveRoute> _topThreeByTime(List<DriveRoute> routes) {
    final sorted = [...routes]..sort((a, b) => a.durationSeconds.compareTo(b.durationSeconds));
    final top = sorted.take(3).toList();
    return [
      for (var i = 0; i < top.length; i++)
        DriveRoute(
          points: top[i].points,
          distanceMeters: top[i].distanceMeters,
          durationSeconds: top[i].durationSeconds,
          trafficDelaySeconds: top[i].trafficDelaySeconds,
          usesLiveTraffic: top[i].usesLiveTraffic,
          viaLabel: top[i].viaLabel,
          index: i,
        ),
    ];
  }

  static String? _normalizeVia(String? raw) {
    if (raw == null) return null;
    var s = raw.trim();
    if (s.isEmpty) return null;
    if (s.toLowerCase().startsWith('via ')) {
      s = s.substring(4).trim();
    }
    return s.isEmpty ? null : s;
  }

  /// Parses Google duration strings like `1234s`.
  static double _parseDurationSeconds(String? raw) {
    if (raw == null || raw.isEmpty) return 0;
    final m = RegExp(r'^(\d+(?:\.\d+)?)s$').firstMatch(raw.trim());
    if (m != null) return double.tryParse(m.group(1)!) ?? 0;
    return double.tryParse(raw) ?? 0;
  }

  /// Decodes a Google encoded polyline into lat/lng points.
  static List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    var index = 0;
    var lat = 0;
    var lng = 0;
    while (index < encoded.length) {
      var shift = 0;
      var result = 0;
      int b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }
}
