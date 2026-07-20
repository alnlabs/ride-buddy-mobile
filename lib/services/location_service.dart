import 'package:geolocator/geolocator.dart';

enum LocationFailure {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  unavailable,
}

class LocationResult {
  const LocationResult._({this.position, this.failure});

  const LocationResult.ok(Position position) : this._(position: position);

  const LocationResult.fail(LocationFailure failure) : this._(failure: failure);

  final Position? position;
  final LocationFailure? failure;

  bool get isOk => position != null;

  String get message {
    switch (failure) {
      case LocationFailure.serviceDisabled:
        return 'Turn on Location / GPS in system settings, then try again';
      case LocationFailure.permissionDenied:
        return 'Allow location access when prompted, then try again';
      case LocationFailure.permissionDeniedForever:
        return 'Location permission is blocked — enable it in app settings';
      case LocationFailure.unavailable:
        return 'Couldn’t read GPS — move outdoors or try again in a moment';
      case null:
        return 'Couldn’t get GPS — enable location and try again';
    }
  }
}

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
    return _requestPermissionIfNeeded();
  }

  /// Always re-check permission (and prompt when denied). Use for explicit taps.
  static Future<LocationResult> currentPositionDetailed({
    bool openSettingsIfBlocked = true,
  }) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (openSettingsIfBlocked) {
          await Geolocator.openLocationSettings();
        }
        return const LocationResult.fail(LocationFailure.serviceDisabled);
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        return const LocationResult.fail(LocationFailure.permissionDenied);
      }
      if (permission == LocationPermission.deniedForever) {
        if (openSettingsIfBlocked) {
          await Geolocator.openAppSettings();
        }
        return const LocationResult.fail(LocationFailure.permissionDeniedForever);
      }
      if (!_isGranted(permission)) {
        return const LocationResult.fail(LocationFailure.permissionDenied);
      }

      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 15),
          ),
        );
        return LocationResult.ok(pos);
      } catch (_) {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) return LocationResult.ok(last);
        return const LocationResult.fail(LocationFailure.unavailable);
      }
    } catch (_) {
      return const LocationResult.fail(LocationFailure.unavailable);
    }
  }

  /// Convenience for callers that only need coordinates (or null).
  static Future<Position?> currentPosition() async {
    final result = await currentPositionDetailed(openSettingsIfBlocked: false);
    return result.position;
  }

  static Future<bool> _requestPermissionIfNeeded() async {
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
}
