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
  /// Extra seconds due to current congestion (TomTom), if known.
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

/// Driving routes — prefers TomTom (live traffic), falls back to OSRM.
/// Always returns up to **3** alternatives sorted by time-to-arrive (fastest first).
class RoutingService {
  RoutingService({Dio? tomtom, Dio? osrm})
      : _tomtom = tomtom ??
            Dio(BaseOptions(
              baseUrl: 'https://api.tomtom.com',
              connectTimeout: const Duration(seconds: 18),
              receiveTimeout: const Duration(seconds: 18),
              headers: {'Accept': 'application/json'},
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

  final Dio _tomtom;
  final Dio _osrm;

  String? get _tomtomKey {
    final k = dotenv.env['TOMTOM_API_KEY']?.trim();
    if (k == null || k.isEmpty || k == 'your_tomtom_key') return null;
    return k;
  }

  /// Top 3 routes by travel time (live traffic when TomTom key is set).
  Future<List<DriveRoute>> routes(LatLng from, LatLng to) async {
    final key = _tomtomKey;
    if (key != null) {
      final live = await _tomtomRoutes(from, to, key);
      if (live.isNotEmpty) return live;
    }
    return _osrmRoutes(from, to);
  }

  Future<List<DriveRoute>> _tomtomRoutes(LatLng from, LatLng to, String key) async {
    try {
      final path =
          '/routing/1/calculateRoute/${from.latitude},${from.longitude}:${to.latitude},${to.longitude}/json';
      final res = await _tomtom.get(path, queryParameters: {
        'key': key,
        'traffic': true,
        'travelMode': 'car',
        'routeType': 'fastest',
        // Primary + up to 2 alternatives → up to 3 total
        'maxAlternatives': 2,
        'computeTravelTimeFor': 'all',
      });
      final data = res.data;
      if (data is! Map) return [];
      final routesJson = data['routes'] as List<dynamic>? ?? [];
      final out = <DriveRoute>[];
      for (final raw in routesJson) {
        final r = raw as Map<String, dynamic>;
        final summary = r['summary'] as Map<String, dynamic>? ?? {};
        final legs = r['legs'] as List<dynamic>? ?? [];
        final points = <LatLng>[];
        for (final leg in legs) {
          final pts = (leg as Map)['points'] as List<dynamic>? ?? [];
          for (final p in pts) {
            final m = p as Map<String, dynamic>;
            points.add(LatLng(
              (m['latitude'] as num).toDouble(),
              (m['longitude'] as num).toDouble(),
            ));
          }
        }
        if (points.length < 2) continue;
        out.add(DriveRoute(
          points: points,
          distanceMeters: (summary['lengthInMeters'] as num?)?.toDouble() ?? 0,
          durationSeconds: (summary['travelTimeInSeconds'] as num?)?.toDouble() ?? 0,
          trafficDelaySeconds: (summary['trafficDelayInSeconds'] as num?)?.toDouble() ?? 0,
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
}
