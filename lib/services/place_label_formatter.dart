/// Builds short public place titles and shortens legacy stored labels.
class PlaceLabelFormatter {
  PlaceLabelFormatter._();

  static const _noise = {
    'india',
    'bharat',
    'telangana',
    'andhra pradesh',
    'karnataka',
    'tamil nadu',
    'maharashtra',
    'delhi',
    'nct',
  };

  /// Public short title from Nominatim `address` + optional name / display_name.
  static String fromNominatim({
    Map<String, dynamic>? address,
    String? name,
    String? displayName,
  }) {
    final landmark = _firstNonEmpty([
      name,
      address?['amenity']?.toString(),
      address?['building']?.toString(),
      address?['tourism']?.toString(),
      address?['shop']?.toString(),
      address?['office']?.toString(),
      address?['leisure']?.toString(),
    ]);
    final road = _firstNonEmpty([
      address?['road']?.toString(),
      address?['pedestrian']?.toString(),
      address?['residential']?.toString(),
    ]);
    final area = _firstNonEmpty([
      address?['suburb']?.toString(),
      address?['neighbourhood']?.toString(),
      address?['neighborhood']?.toString(),
      address?['quarter']?.toString(),
      address?['city_district']?.toString(),
      address?['village']?.toString(),
      address?['hamlet']?.toString(),
      address?['locality']?.toString(),
    ]);
    final city = _firstNonEmpty([
      address?['city']?.toString(),
      address?['town']?.toString(),
      address?['municipality']?.toString(),
      address?['county']?.toString(),
    ]);

    final parts = <String>[];
    if (landmark != null) {
      parts.add(landmark);
      if (area != null && !_same(area, landmark)) parts.add(area);
      if (city != null && !_same(city, landmark) && !_same(city, area) && parts.length < 3) {
        parts.add(city);
      }
    } else if (road != null) {
      parts.add(road);
      if (area != null && !_same(area, road)) parts.add(area);
      if (city != null && !_same(city, road) && !_same(city, area) && parts.length < 3) {
        parts.add(city);
      }
    } else if (area != null) {
      parts.add(area);
      if (city != null && !_same(city, area)) parts.add(city);
    } else if (city != null) {
      parts.add(city);
    }

    if (parts.isNotEmpty) return parts.take(3).join(', ');
    return shortenStoredLabel(displayName ?? name ?? 'Unknown');
  }

  static String fromPhoton(Map<String, dynamic> props) {
    final name = props['name']?.toString();
    final street = props['street']?.toString();
    final area = _firstNonEmpty([
      props['district']?.toString(),
      props['locality']?.toString(),
      props['county']?.toString(),
    ]);
    final city = _firstNonEmpty([
      props['city']?.toString(),
      props['town']?.toString(),
      props['village']?.toString(),
    ]);
    return fromNominatim(
      address: {
        if (name != null) 'amenity': name,
        if (street != null) 'road': street,
        if (area != null) 'suburb': area,
        if (city != null) 'city': city,
        if (props['state'] != null) 'state': props['state'],
      },
      name: name,
      displayName: [name, street, city].whereType<String>().join(', '),
    );
  }

  /// Short title from Google Places (New) display name + address components.
  static String fromGoogle({
    String? displayName,
    String? formattedAddress,
    List<dynamic>? addressComponents,
  }) {
    String? pick(Set<String> types) {
      if (addressComponents == null) return null;
      for (final raw in addressComponents) {
        if (raw is! Map) continue;
        final typeList = (raw['types'] as List<dynamic>? ?? []).map((e) => '$e').toSet();
        if (typeList.intersection(types).isEmpty) continue;
        final long = raw['longText']?.toString() ?? raw['long_name']?.toString();
        if (long != null && long.trim().isNotEmpty) return long.trim();
      }
      return null;
    }

    final landmark = displayName?.trim();
    final area = _firstNonEmpty([
      pick({'sublocality_level_1', 'sublocality', 'neighborhood'}),
      pick({'sublocality_level_2'}),
    ]);
    final city = _firstNonEmpty([
      pick({'locality'}),
      pick({'administrative_area_level_3'}),
      pick({'administrative_area_level_2'}),
    ]);
    return fromNominatim(
      address: {
        if (landmark != null && landmark.isNotEmpty) 'amenity': landmark,
        if (area != null) 'suburb': area,
        if (city != null) 'city': city,
      },
      name: landmark,
      displayName: formattedAddress ?? landmark,
    );
  }

  /// Shorten a legacy long comma-separated label for list cards.
  static String shortenStoredLabel(String label, {int maxParts = 3}) {
    final trimmed = label.trim();
    if (trimmed.isEmpty) return 'Unknown';
    final raw = trimmed
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .where((s) => !_isNoise(s))
        .where((s) => !RegExp(r'^\d{5,6}$').hasMatch(s))
        .toList();
    if (raw.isEmpty) {
      return trimmed.length <= 40 ? trimmed : '${trimmed.substring(0, 38)}…';
    }
    final parts = <String>[];
    for (final p in raw) {
      if (parts.any((e) => _same(e, p))) continue;
      parts.add(p);
      if (parts.length >= maxParts) break;
    }
    return parts.join(', ');
  }

  static String? _firstNonEmpty(List<String?> values) {
    for (final v in values) {
      if (v == null) continue;
      final t = v.trim();
      if (t.isNotEmpty && !_isNoise(t)) return t;
    }
    return null;
  }

  static bool _isNoise(String s) {
    final lower = s.toLowerCase().trim();
    if (_noise.contains(lower)) return true;
    if (lower.endsWith(' district') || lower.endsWith(' mandal')) return true;
    return false;
  }

  static bool _same(String? a, String? b) {
    if (a == null || b == null) return false;
    return a.trim().toLowerCase() == b.trim().toLowerCase();
  }
}
