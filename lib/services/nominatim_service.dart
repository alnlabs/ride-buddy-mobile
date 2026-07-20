import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ridebuddy/services/place_label_formatter.dart';

final nominatimServiceProvider = Provider((ref) => NominatimService());

/// Max straight-line distance for place suggestions / local trips (commute app).
const double kMaxLocalSearchKm = 100;

class PlaceSuggestion {
  PlaceSuggestion({
    required this.publicShort,
    required this.lat,
    required this.lng,
    this.fullAddress,
    this.privateLabel,
    this.city,
    this.savedPlaceId,
    this.kind,
  });

  /// Short public area/landmark (what others see on rides).
  final String publicShort;

  /// Full geocode string; shown when toggled.
  final String? fullAddress;

  /// Owner-only name (saved home/office or personal nickname).
  final String? privateLabel;

  final double lat;
  final double lng;
  final String? city;
  final String? savedPlaceId;
  /// home | office when from saved places.
  final String? kind;

  /// Field / list title for the current user (private if set).
  String get label =>
      (privateLabel != null && privateLabel!.trim().isNotEmpty) ? privateLabel!.trim() : publicShort;

  String displayTitle({required bool isOwner}) {
    if (isOwner && privateLabel != null && privateLabel!.trim().isNotEmpty) {
      return privateLabel!.trim();
    }
    return publicShort;
  }

  PlaceSuggestion copyWith({
    String? publicShort,
    String? fullAddress,
    String? privateLabel,
    double? lat,
    double? lng,
    String? city,
    String? savedPlaceId,
    String? kind,
  }) {
    return PlaceSuggestion(
      publicShort: publicShort ?? this.publicShort,
      fullAddress: fullAddress ?? this.fullAddress,
      privateLabel: privateLabel ?? this.privateLabel,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      city: city ?? this.city,
      savedPlaceId: savedPlaceId ?? this.savedPlaceId,
      kind: kind ?? this.kind,
    );
  }
}

/// Place search — prefers Google Places when keyed; falls back to
/// Nominatim + Photon. Biases locally, caps at [kMaxLocalSearchKm].
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
    _google = Dio(BaseOptions(
      baseUrl: 'https://places.googleapis.com',
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 12),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      validateStatus: (code) => code != null && code >= 200 && code < 500,
    ));
  }

  late final Dio _nominatim;
  late final Dio _photon;
  late final Dio _google;

  String? get _googleKey {
    final k = dotenv.env['GOOGLE_MAPS_API_KEY']?.trim();
    if (k == null || k.isEmpty || k == 'your_google_maps_key') return null;
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

    final googleKey = _googleKey;
    if (googleKey != null) {
      final google = await _searchGoogle(
        q,
        key: googleKey,
        country: country,
        nearLat: nearLat,
        nearLng: nearLng,
        maxDistanceKm: maxDistanceKm,
      );
      if (google.isNotEmpty) {
        return _dedupeFilterSort(
          google,
          nearLat,
          nearLng,
          maxDistanceKm,
          query: q,
        );
      }
    }

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

    final chunks = await Future.wait(tasks);
    final merged = <PlaceSuggestion>[];
    for (final chunk in chunks) {
      merged.addAll(chunk);
    }
    return _dedupeFilterSort(
      merged,
      nearLat,
      nearLng,
      maxDistanceKm,
      query: q,
    );
  }

  Future<List<PlaceSuggestion>> _searchGoogle(
    String query, {
    required String key,
    required String country,
    double? nearLat,
    double? nearLng,
    required double maxDistanceKm,
  }) async {
    try {
      final session = _sessionToken();
      final body = <String, dynamic>{
        'input': query,
        'includedRegionCodes': [country.toLowerCase()],
        'languageCode': 'en',
        'sessionToken': session,
      };
      if (nearLat != null && nearLng != null) {
        body['locationBias'] = {
          'circle': {
            'center': {'latitude': nearLat, 'longitude': nearLng},
            'radius': (maxDistanceKm * 1000).clamp(1000, 50000).toDouble(),
          },
        };
      }

      final auto = await _google.post(
        '/v1/places:autocomplete',
        data: body,
        options: Options(headers: {
          'X-Goog-Api-Key': key,
          'X-Goog-FieldMask':
              'suggestions.placePrediction.place,suggestions.placePrediction.placeId,'
              'suggestions.placePrediction.text,suggestions.placePrediction.structuredFormat',
        }),
      );
      if (auto.statusCode != 200 || auto.data is! Map) return [];
      final suggestions = (auto.data as Map)['suggestions'] as List<dynamic>? ?? [];
      final placeNames = <String>[];
      for (final s in suggestions) {
        if (s is! Map) continue;
        final pred = s['placePrediction'] as Map<String, dynamic>?;
        if (pred == null) continue;
        final resource = pred['place']?.toString();
        final id = pred['placeId']?.toString();
        if (resource != null && resource.startsWith('places/')) {
          placeNames.add(resource);
        } else if (id != null && id.isNotEmpty) {
          placeNames.add('places/$id');
        }
        if (placeNames.length >= 8) break;
      }
      if (placeNames.isEmpty) return [];

      final details = await Future.wait(
        placeNames.map((name) => _googlePlaceDetails(name, key: key, sessionToken: session)),
      );
      return details.whereType<PlaceSuggestion>().toList();
    } catch (_) {
      return [];
    }
  }

  Future<PlaceSuggestion?> _googlePlaceDetails(
    String placeResourceName, {
    required String key,
    required String sessionToken,
  }) async {
    try {
      final path = placeResourceName.startsWith('/') ? placeResourceName : '/v1/$placeResourceName';
      final res = await _google.get(
        path,
        queryParameters: {'sessionToken': sessionToken},
        options: Options(headers: {
          'X-Goog-Api-Key': key,
          'X-Goog-FieldMask':
              'id,displayName,formattedAddress,location,addressComponents',
        }),
      );
      if (res.statusCode != 200 || res.data is! Map) return null;
      final m = res.data as Map<String, dynamic>;
      final loc = m['location'] as Map<String, dynamic>?;
      final lat = (loc?['latitude'] as num?)?.toDouble();
      final lng = (loc?['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) return null;
      final displayName = (m['displayName'] is Map)
          ? (m['displayName'] as Map)['text']?.toString()
          : m['displayName']?.toString();
      final formatted = m['formattedAddress']?.toString();
      final components = m['addressComponents'] as List<dynamic>?;
      return PlaceSuggestion(
        publicShort: PlaceLabelFormatter.fromGoogle(
          displayName: displayName,
          formattedAddress: formatted,
          addressComponents: components,
        ),
        fullAddress: formatted ?? displayName,
        lat: lat,
        lng: lng,
        city: _cityFromGoogleComponents(components),
      );
    } catch (_) {
      return null;
    }
  }

  static String _sessionToken() {
    final r = math.Random();
    String hex(int n) => List.generate(n, (_) => r.nextInt(16).toRadixString(16)).join();
    return '${hex(8)}-${hex(4)}-4${hex(3)}-${hex(4)}-${hex(12)}';
  }

  static String? _cityFromGoogleComponents(List<dynamic>? components) {
    if (components == null) return null;
    String? pick(Set<String> want) {
      for (final raw in components) {
        if (raw is! Map) continue;
        final types = (raw['types'] as List<dynamic>? ?? []).map((e) => '$e').toSet();
        if (types.intersection(want).isEmpty) continue;
        final t = raw['longText']?.toString() ?? raw['long_name']?.toString();
        if (t != null && t.trim().isNotEmpty) return t.trim();
      }
      return null;
    }

    return pick({'locality'}) ??
        pick({'administrative_area_level_3'}) ??
        pick({'administrative_area_level_2'});
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
        final displayName = m['display_name'] as String? ?? 'Unknown';
        final name = m['name'] as String?;
        return PlaceSuggestion(
          publicShort: PlaceLabelFormatter.fromNominatim(
            address: address,
            name: name,
            displayName: displayName,
          ),
          fullAddress: displayName,
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
        final publicShort = PlaceLabelFormatter.fromPhoton(props);
        final fullParts = <String>[
          if (name != null && name.isNotEmpty) name,
          if (street != null && street.isNotEmpty && street != name) street,
          if (city != null && city.isNotEmpty) city,
          if (props['state'] != null) props['state'].toString(),
        ];
        return PlaceSuggestion(
          publicShort: publicShort,
          fullAddress: fullParts.isNotEmpty ? fullParts.join(', ') : publicShort,
          lat: lat,
          lng: lng,
          city: city,
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
      final displayName = m['display_name'] as String?;
      if (displayName == null) return null;
      final address = m['address'] as Map<String, dynamic>?;
      final name = m['name'] as String?;
      return PlaceSuggestion(
        publicShort: PlaceLabelFormatter.fromNominatim(
          address: address,
          name: name,
          displayName: displayName,
        ),
        fullAddress: displayName,
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
        final publicShort = PlaceLabelFormatter.fromPhoton(props);
        return PlaceSuggestion(
          publicShort: publicShort,
          fullAddress: [
            if (props['name'] != null) props['name'].toString(),
            if (city != null) city,
            if (props['state'] != null) props['state'].toString(),
          ].where((e) => e.isNotEmpty).join(', '),
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
    double maxDistanceKm, {
    String? query,
  }) {
    final seen = <String>{};
    final unique = <PlaceSuggestion>[];
    for (final p in list) {
      final key =
          '${p.publicShort.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim()}|'
          '${p.lat.toStringAsFixed(3)},${p.lng.toStringAsFixed(3)}';
      if (!seen.add(key)) continue;
      unique.add(p);
    }

    final q = (query ?? '').trim();
    final scored = <({PlaceSuggestion p, int text, double dist, int order})>[];
    for (var i = 0; i < unique.length; i++) {
      final p = unique[i];
      final dist = (nearLat != null && nearLng != null)
          ? distanceKm(nearLat, nearLng, p.lat, p.lng)
          : 0.0;
      if (nearLat != null && nearLng != null && dist > maxDistanceKm) continue;
      scored.add((p: p, text: _textMatchRank(p, q), dist: dist, order: i));
    }

    // Exact / strong text matches first, then nearer results, then original order.
    scored.sort((a, b) {
      final byText = a.text.compareTo(b.text);
      if (byText != 0) return byText;
      final byDist = a.dist.compareTo(b.dist);
      if (byDist != 0) return byDist;
      return a.order.compareTo(b.order);
    });
    return scored.map((e) => e.p).take(15).toList();
  }

  /// Lower is better: 0 exact, 1 prefix, 2 word-start, 3 contains, 4 tokens, 10 weak.
  static int _textMatchRank(PlaceSuggestion p, String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return 5;
    final short = p.publicShort.toLowerCase().trim();
    final label = p.label.toLowerCase().trim();
    final full = (p.fullAddress ?? '').toLowerCase().trim();
    final hay = '$short · $label · $full';

    if (short == q || label == q || full == q) return 0;
    if (short.startsWith(q) || label.startsWith(q) || full.startsWith(q)) return 1;

    final wordStart = RegExp('(^|\\s|[,·\\-/])${RegExp.escape(q)}');
    if (wordStart.hasMatch(short) || wordStart.hasMatch(label) || wordStart.hasMatch(full)) {
      return 2;
    }
    if (short.contains(q) || label.contains(q) || full.contains(q)) return 3;

    final tokens = q.split(RegExp(r'\s+')).where((t) => t.length >= 2).toList();
    if (tokens.isNotEmpty && tokens.every(hay.contains)) return 4;
    return 10;
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
