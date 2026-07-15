import 'package:geolocator/geolocator.dart';

/// Location helpers for ride maps / pickup defaults.
class LocationService {
  LocationService._();

  static bool _promptedThisSession = false;

  /// Ask for when-in-use location on launch (once per session).
  /// Returns true if permission is granted (or already granted).
  static Future<bool> ensurePermissionOnStartup() async {
    if (_promptedThisSession) {
      return _isGranted(await Geolocator.checkPermission());
    }
    _promptedThisSession = true;

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Still request permission so the OS dialog can appear next time location is needed.
        // Opening settings automatically on cold start is too aggressive.
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      return _isGranted(permission);
    } catch (_) {
      return false;
    }
  }

  static bool _isGranted(LocationPermission permission) {
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  static Future<Position?> currentPosition() async {
    final granted = await ensurePermissionOnStartup();
    if (!granted) return null;
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (_) {
      return null;
    }
  }
}
