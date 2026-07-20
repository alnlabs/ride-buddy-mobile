import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

final routingServiceProvider = Provider((ref) => RoutingService());

class DriveRoute {
  DriveRoute({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
    this.trafficDelaySeconds = 0,
    this.index = 0,
    this.usesLiveTraffic = false,
  });

  final List<LatLng> points;
  final double distanceMeters;
  /// Estimated travel time including traffic when [usesLiveTraffic] is true.
  final double durationSeconds;
  /// Extra seconds due to current congestion, if known.
  final double trafficDelaySeconds;
  final int index;
  final bool usesLiveTraffic;

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

  /// Chip / list label ranked by arrival time (0 = fastest).
  String get rankLabel {
    if (index == 0) return 'Fastest';
    if (index == 1) return '2nd';
    if (index == 2) return '3rd';
    return 'Alt ${index + 1}';
  }

  String get chipLabel {
    final live = usesLiveTraffic ? ' · traffic' : '';
    return '$rankLabel · $durationLabel · $distanceLabel$live';
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
}

/// Driving routes — prefers Google Routes (live traffic), falls back to OSRM.
/// Always returns up to **3** alternatives sorted by time-to-arrive (fastest first).
class RoutingService {
  RoutingService({Dio? google, Dio? osrm})
      : _google = google ??
            Dio(BaseOptions(
              baseUrl: 'https://routes.googleapis.com',
              connectTimeout: const Duration(seconds: 18),
              receiveTimeout: const Duration(seconds: 18),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              validateStatus: (code) => code != null && code >= 200 && code < 500,
            )),
        _osrm = osrm ??
            Dio(BaseOptions(
              baseUrl: 'https://router.project-osrm.org',
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
              headers: {
                'User-Agent': 'RideBuddy/1.0 (com.alnlabs.ridebuddy)',
                'Accept': 'application/json',
              },
            ));

  final Dio _google;
  final Dio _osrm;

  String? get _googleKey {
    final k = dotenv.env['GOOGLE_MAPS_API_KEY']?.trim();
    if (k == null || k.isEmpty || k == 'your_google_maps_key') return null;
    return k;
  }

  /// Top 3 routes by travel time (live traffic when Google key is set).
  Future<List<DriveRoute>> routes(LatLng from, LatLng to) async {
    final key = _googleKey;
    if (key != null) {
      final live = await _googleRoutes(from, to, key);
      if (live.isNotEmpty) return live;
    }
    return _osrmRoutes(from, to);
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
          'routingPreference': 'TRAFFIC_AWARE',
          'computeAlternativeRoutes': true,
          'languageCode': 'en-IN',
          'regionCode': 'IN',
          'units': 'METRIC',
        },
        options: Options(headers: {
          'X-Goog-Api-Key': key,
          'X-Goog-FieldMask':
              'routes.duration,routes.staticDuration,routes.distanceMeters,'
              'routes.polyline.encodedPolyline',
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
          index: i,
        ),
    ];
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
