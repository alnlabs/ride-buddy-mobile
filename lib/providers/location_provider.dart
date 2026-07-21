import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:ridebuddy/providers/auth_provider.dart';
import 'package:ridebuddy/services/location_service.dart';
import 'package:ridebuddy/services/nominatim_service.dart';
import 'package:ridebuddy/services/place_label_formatter.dart';

/// GPS position + city (reverse geocode). Optional — may be null if denied/offline.
final userLocationProvider = FutureProvider.autoDispose<PlaceSuggestion?>((ref) async {
  ref.watch(authStateProvider.select((s) => s.userId));
  final pos = await LocationService.currentPosition();
  if (pos == null) return null;
  return ref.read(nominatimServiceProvider).reverseDetailed(pos.latitude, pos.longitude);
});

/// Default map region from profile office (city + coordinates).
/// Falls back to GPS, then Hyderabad.
final officeMapRegionProvider = FutureProvider.autoDispose<OfficeMapRegion>((ref) async {
  ref.watch(authStateProvider.select((s) => s.userId));
  final nominatim = ref.read(nominatimServiceProvider);

  try {
    final profile = await ref.watch(profileProvider.future);
    if (profile.officeLat != null && profile.officeLng != null) {
      final officeDetailed = await nominatim.reverseDetailed(profile.officeLat!, profile.officeLng!);
      final city = officeDetailed?.city ?? _cityGuessFromLabel(profile.officeLabel);

      PlaceSuggestion? home;
      if (profile.homeLat != null && profile.homeLng != null) {
        final homeDetailed = await nominatim.reverseDetailed(profile.homeLat!, profile.homeLng!);
        final homePrivate = (profile.homeLabel != null && profile.homeLabel!.trim().isNotEmpty)
            ? profile.homeLabel!.trim()
            : 'Home';
        home = PlaceSuggestion(
          // Area/landmark for the field — never force the word "Home" here.
          publicShort: homeDetailed?.publicShort ??
              PlaceLabelFormatter.shortenStoredLabel(
                homeDetailed?.fullAddress ?? profile.homeLabel ?? 'Home',
              ),
          fullAddress: homeDetailed?.fullAddress ?? profile.homeLabel,
          privateLabel: homePrivate,
          lat: profile.homeLat!,
          lng: profile.homeLng!,
          kind: 'home',
        );
      }

      final officePrivate = (profile.officeLabel != null && profile.officeLabel!.trim().isNotEmpty)
          ? profile.officeLabel!.trim()
          : 'Office';
      return OfficeMapRegion(
        center: LatLng(profile.officeLat!, profile.officeLng!),
        city: city,
        office: PlaceSuggestion(
          publicShort: officeDetailed?.publicShort ??
              PlaceLabelFormatter.shortenStoredLabel(
                officeDetailed?.fullAddress ?? profile.officeLabel ?? 'Office',
              ),
          fullAddress: officeDetailed?.fullAddress ?? profile.officeLabel,
          privateLabel: officePrivate,
          lat: profile.officeLat!,
          lng: profile.officeLng!,
          city: city,
          kind: 'office',
        ),
        home: home,
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
