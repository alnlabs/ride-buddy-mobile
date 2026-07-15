import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final nominatimServiceProvider = Provider((ref) => NominatimService());

/// Max straight-line distance for place suggestions / local trips (commute app).
const double kMaxLocalSearchKm = 100;

class PlaceSuggestion {
  PlaceSuggestion({
    required this.label,
    required this.lat,
    required this.lng,
    this.city,
  });

  final String label;
  final double lat;
  final double lng;
  final String? city;
}

/// Place search via Nominatim + Photon (+ TomTom when keyed).
/// Biases to the local area, then keeps results within [kMaxLocalSearchKm].
class NominatimService {
  NominatimService() {
    _nominatim = Dio(BaseOptions(
      baseUrl: 'https://nominatim.openstreetmap.org',
      headers: {
        'User-Agent': 'RideBuddy/1.0 (com.alnlabs.ridebuddy; +https://alnlabs.com)',
        'Accept': 'application/json',
      },
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 12),
      validateStatus: (code) => code != null && code >= 200 && code < 500,
    ));
    _photon = Dio(BaseOptions(
      baseUrl: 'https://photon.komoot.io',
      headers: {
        'User-Agent': 'RideBuddy/1.0 (com.alnlabs.ridebuddy)',
        'Accept': 'application/json',
      },
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 12),
    ));
    _tomtom = Dio(BaseOptions(
      baseUrl: 'https://api.tomtom.com',
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 12),
      headers: {'Accept': 'application/json'},
    ));
  }

  late final Dio _nominatim;
  late final Dio _photon;
  late final Dio _tomtom;

  String? get _tomtomKey {
    final k = dotenv.env['TOMTOM_API_KEY']?.trim();
    if (k == null || k.isEmpty || k == 'your_tomtom_key') return null;
    return k;
  }

  /// Search places near [nearLat]/[nearLng], capped at [maxDistanceKm].
  Future<List<PlaceSuggestion>> search(
    String query, {
    String country = 'in',
    String? city,
    double? nearLat,
    double? nearLng,
    double maxDistanceKm = kMaxLocalSearchKm,
  }) async {
    final q = query.trim();
    if (q.length < 2) return [];

    final tasks = <Future<List<PlaceSuggestion>>>[
      // Soft viewbox (bounded=0) — finds more matches; we distance-filter after
      _searchNominatim(
        q,
        country: country,
        nearLat: nearLat,
        nearLng: nearLng,
        maxDistanceKm: maxDistanceKm,
        appendCity: null,
      ),
      // Photon location bias (no hard bbox — bbox drops too many Indian places)
      _searchPhoton(q, nearLat: nearLat, nearLng: nearLng),
    ];

    if (city != null && city.trim().isNotEmpty) {
      tasks.add(_searchNominatim(
        q,
        country: country,
        nearLat: nearLat,
        nearLng: nearLng,
        maxDistanceKm: maxDistanceKm,
        appendCity: city.trim(),
      ));
      if (!q.toLowerCase().contains(city.toLowerCase())) {
        tasks.add(_searchPhoton('$q, $city', nearLat: nearLat, nearLng: nearLng));
      }
    }

    final key = _tomtomKey;
    if (key != null && nearLat != null && nearLng != null) {
      tasks.add(_searchTomtom(
        q,
        key: key,
        nearLat: nearLat,
        nearLng: nearLng,
        maxDistanceKm: maxDistanceKm,
        country: country,
      ));
    }

    final chunks = await Future.wait(tasks);
    final merged = <PlaceSuggestion>[];
    for (final chunk in chunks) {
      merged.addAll(chunk);
    }
    return _dedupeFilterSort(merged, nearLat, nearLng, maxDistanceKm);
  }

  Future<List<PlaceSuggestion>> _searchNominatim(
    String query, {
    required String country,
    double? nearLat,
    double? nearLng,
    required double maxDistanceKm,
    String? appendCity,
  }) async {
    try {
      var q = query;
      if (appendCity != null &&
          appendCity.isNotEmpty &&
          appendCity.length < 40 &&
          !q.toLowerCase().contains(appendCity.toLowerCase())) {
        q = '$q, $appendCity';
      }
      final params = <String, dynamic>{
        'q': q,
        'format': 'jsonv2',
        'addressdetails': 1,
        'limit': 20,
        'countrycodes': country,
      };
      if (nearLat != null && nearLng != null) {
        final box = _viewbox(nearLat, nearLng, maxDistanceKm);
        // Soft bias only — hard bound=1 often returns empty for local landmarks.
        params['viewbox'] = '${box.minLng},${box.maxLat},${box.maxLng},${box.minLat}';
        params['bounded'] = 0;
      }
      final res = await _nominatim.get('/search', queryParameters: params);
      if (res.statusCode == 429 || res.statusCode == 403) return [];
      final data = res.data;
      if (data is! List) return [];
      return data.map((e) {
        final m = e as Map<String, dynamic>;
        final address = m['address'] as Map<String, dynamic>?;
        return PlaceSuggestion(
          label: m['display_name'] as String? ?? 'Unknown',
          lat: double.parse('${m['lat']}'),
          lng: double.parse('${m['lon']}'),
          city: _cityFromAddress(address),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<PlaceSuggestion>> _searchPhoton(
    String query, {
    double? nearLat,
    double? nearLng,
  }) async {
    try {
      final params = <String, dynamic>{
        'q': query,
        'limit': 20,
        'lang': 'en',
      };
      if (nearLat != null && nearLng != null) {
        params['lat'] = nearLat;
        params['lon'] = nearLng;
        // Prefer nearby; no bbox (hard bbox missed many India place names).
      }
      final res = await _photon.get('/api/', queryParameters: params);
      final data = res.data;
      if (data is! Map) return [];
      final features = data['features'] as List<dynamic>? ?? [];
      return features.map((f) {
        final feature = f as Map<String, dynamic>;
        final props = feature['properties'] as Map<String, dynamic>? ?? {};
        final geometry = feature['geometry'] as Map<String, dynamic>? ?? {};
        final coords = geometry['coordinates'] as List<dynamic>? ?? [];
        final lng = (coords.isNotEmpty ? coords[0] as num : 0).toDouble();
        final lat = (coords.length > 1 ? coords[1] as num : 0).toDouble();
        final name = props['name']?.toString();
        final street = props['street']?.toString();
        final city = props['city']?.toString() ??
            props['town']?.toString() ??
            props['village']?.toString() ??
            props['county']?.toString();
        final state = props['state']?.toString();
        final district = props['district']?.toString() ?? props['county']?.toString();
        final parts = <String>[
          if (name != null && name.isNotEmpty) name,
          if (street != null && street.isNotEmpty && street != name) street,
          if (district != null && district.isNotEmpty && district != city) district,
          if (city != null && city.isNotEmpty) city,
          if (state != null && state.isNotEmpty) state,
        ];
        return PlaceSuggestion(
          label: parts.isNotEmpty ? parts.join(', ') : (name ?? 'Unknown'),
          lat: lat,
          lng: lng,
          city: city,
        );
      }).where((p) => p.lat != 0 || p.lng != 0).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<PlaceSuggestion>> _searchTomtom(
    String query, {
    required String key,
    required double nearLat,
    required double nearLng,
    required double maxDistanceKm,
    required String country,
  }) async {
    try {
      final encoded = Uri.encodeComponent(query);
      final res = await _tomtom.get(
        '/search/2/search/$encoded.json',
        queryParameters: {
          'key': key,
          'lat': nearLat,
          'lon': nearLng,
          'radius': (maxDistanceKm * 1000).round(),
          'limit': 20,
          'countrySet': country.toUpperCase(),
          'typeahead': true,
          'idxSet': 'POI,PAD,Addr,Str,Geo',
        },
      );
      final data = res.data;
      if (data is! Map) return [];
      final results = data['results'] as List<dynamic>? ?? [];
      return results.map((e) {
        final m = e as Map<String, dynamic>;
        final pos = m['position'] as Map<String, dynamic>? ?? {};
        final addr = m['address'] as Map<String, dynamic>? ?? {};
        final poi = m['poi'] as Map<String, dynamic>?;
        final name = poi?['name']?.toString();
        final freeform = addr['freeformAddress']?.toString();
        final municipality = addr['municipality']?.toString() ??
            addr['municipalitySubdivision']?.toString() ??
            addr['localName']?.toString();
        final label = [
          if (name != null && name.isNotEmpty) name,
          if (freeform != null && freeform.isNotEmpty && freeform != name) freeform,
        ].join(', ');
        return PlaceSuggestion(
          label: label.isNotEmpty ? label : (freeform ?? name ?? 'Unknown'),
          lat: (pos['lat'] as num?)?.toDouble() ?? 0,
          lng: (pos['lon'] as num?)?.toDouble() ?? 0,
          city: municipality,
        );
      }).where((p) => p.lat != 0 || p.lng != 0).toList();
    } catch (_) {
      return [];
    }
  }

  Future<PlaceSuggestion?> reverse(double lat, double lng) async {
    return reverseDetailed(lat, lng);
  }

  Future<PlaceSuggestion?> reverseDetailed(double lat, double lng) async {
    try {
      final res = await _nominatim.get(
        '/reverse',
        queryParameters: {
          'lat': lat,
          'lon': lng,
          'format': 'jsonv2',
          'addressdetails': 1,
        },
      );
      if (res.data is! Map) return null;
      final m = res.data as Map<String, dynamic>;
      final name = m['display_name'] as String?;
      if (name == null) return null;
      final address = m['address'] as Map<String, dynamic>?;
      return PlaceSuggestion(
        label: name,
        lat: lat,
        lng: lng,
        city: _cityFromAddress(address),
      );
    } catch (_) {
      try {
        final res = await _photon.get(
          '/reverse',
          queryParameters: {'lat': lat, 'lon': lng},
        );
        final data = res.data;
        if (data is! Map) return null;
        final features = data['features'] as List<dynamic>? ?? [];
        if (features.isEmpty) return null;
        final props = (features.first as Map)['properties'] as Map<String, dynamic>? ?? {};
        final city = props['city']?.toString() ?? props['town']?.toString();
        final name = props['name']?.toString();
        final parts = [
          if (name != null) name,
          if (city != null) city,
          if (props['state'] != null) props['state'].toString(),
        ];
        return PlaceSuggestion(
          label: parts.join(', '),
          lat: lat,
          lng: lng,
          city: city,
        );
      } catch (_) {
        return null;
      }
    }
  }

  static double distanceKm(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLng = _rad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(lat1)) * math.cos(_rad(lat2)) * math.sin(dLng / 2) * math.sin(dLng / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static bool withinLocalTrip(
    double originLat,
    double originLng,
    double destLat,
    double destLng, {
    double maxKm = kMaxLocalSearchKm,
  }) {
    return distanceKm(originLat, originLng, destLat, destLng) <= maxKm;
  }

  static double _rad(double deg) => deg * math.pi / 180;

  static ({double minLat, double maxLat, double minLng, double maxLng}) _viewbox(
    double lat,
    double lng,
    double maxKm,
  ) {
    final latDelta = maxKm / 111.0;
    final cosLat = math.cos(_rad(lat)).abs().clamp(0.2, 1.0);
    final lngDelta = maxKm / (111.0 * cosLat);
    return (
      minLat: lat - latDelta,
      maxLat: lat + latDelta,
      minLng: lng - lngDelta,
      maxLng: lng + lngDelta,
    );
  }

  static List<PlaceSuggestion> _dedupeFilterSort(
    List<PlaceSuggestion> list,
    double? nearLat,
    double? nearLng,
    double maxDistanceKm,
  ) {
    final seen = <String>{};
    final unique = <PlaceSuggestion>[];
    for (final p in list) {
      final key =
          '${p.label.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim()}|'
          '${p.lat.toStringAsFixed(3)},${p.lng.toStringAsFixed(3)}';
      if (!seen.add(key)) continue;
      unique.add(p);
    }

    if (nearLat == null || nearLng == null) {
      return unique.take(15).toList();
    }

    final withDist = unique
        .map((p) => (p: p, d: distanceKm(nearLat, nearLng, p.lat, p.lng)))
        .where((e) => e.d <= maxDistanceKm)
        .toList()
      ..sort((a, b) => a.d.compareTo(b.d));
    return withDist.map((e) => e.p).take(15).toList();
  }

  static String? _cityFromAddress(Map<String, dynamic>? address) {
    if (address == null) return null;
    for (final key in ['city', 'town', 'village', 'municipality', 'state_district', 'county']) {
      final v = address[key];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }
}
