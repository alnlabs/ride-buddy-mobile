import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:ridebuddy/providers/auth_provider.dart';
import 'package:ridebuddy/services/location_service.dart';
import 'package:ridebuddy/services/nominatim_service.dart';

/// GPS position + city (reverse geocode). Optional — may be null if denied/offline.
final userLocationProvider = FutureProvider<PlaceSuggestion?>((ref) async {
  final pos = await LocationService.currentPosition();
  if (pos == null) return null;
  return ref.read(nominatimServiceProvider).reverseDetailed(pos.latitude, pos.longitude);
});

/// Default map region from profile office (city + coordinates).
/// Falls back to GPS, then Hyderabad.
final officeMapRegionProvider = FutureProvider<OfficeMapRegion>((ref) async {
  final nominatim = ref.read(nominatimServiceProvider);

  try {
    final profile = await ref.watch(profileProvider.future);
    if (profile.officeLat != null && profile.officeLng != null) {
      final detailed = await nominatim.reverseDetailed(profile.officeLat!, profile.officeLng!);
      final city = detailed?.city ?? _cityGuessFromLabel(profile.officeLabel);
      return OfficeMapRegion(
        center: LatLng(profile.officeLat!, profile.officeLng!),
        city: city,
        office: PlaceSuggestion(
          label: profile.officeLabel ?? detailed?.label ?? 'Office',
          lat: profile.officeLat!,
          lng: profile.officeLng!,
          city: city,
        ),
        home: profile.homeLat != null
            ? PlaceSuggestion(
                label: profile.homeLabel ?? 'Home',
                lat: profile.homeLat!,
                lng: profile.homeLng!,
              )
            : null,
        source: OfficeMapRegionSource.office,
      );
    }
  } catch (_) {}

  try {
    final gps = await ref.read(userLocationProvider.future);
    if (gps != null) {
      return OfficeMapRegion(
        center: LatLng(gps.lat, gps.lng),
        city: gps.city,
        office: null,
        home: null,
        source: OfficeMapRegionSource.gps,
      );
    }
  } catch (_) {}

  return OfficeMapRegion.hyderabad;
});

String? _cityGuessFromLabel(String? label) {
  if (label == null || label.trim().isEmpty) return null;
  // Nominatim labels are usually "…, Neighborhood, City, State, …"
  final parts = label.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  if (parts.length >= 3) return parts[parts.length >= 4 ? parts.length - 4 : 1];
  if (parts.length == 2) return parts.first;
  return parts.isNotEmpty ? parts.first : null;
}

enum OfficeMapRegionSource { office, gps, fallback }

class OfficeMapRegion {
  const OfficeMapRegion({
    required this.center,
    required this.source,
    this.city,
    this.office,
    this.home,
  });

  final LatLng center;
  final String? city;
  final PlaceSuggestion? office;
  final PlaceSuggestion? home;
  final OfficeMapRegionSource source;

  /// India HQ-style fallback when profile/GPS unavailable.
  static const hyderabad = OfficeMapRegion(
    center: LatLng(17.3850, 78.4867),
    city: 'Hyderabad',
    source: OfficeMapRegionSource.fallback,
  );

  double get lat => center.latitude;
  double get lng => center.longitude;
}
