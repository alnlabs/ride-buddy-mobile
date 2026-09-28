import * as Location from 'expo-location';

export type LocationFailure = 'serviceDisabled' | 'permissionDenied' | 'permissionDeniedForever' | 'unavailable';

export type LocationResult =
  | { ok: true; lat: number; lng: number }
  | { ok: false; failure: LocationFailure; message: string };

const messages: Record<LocationFailure, string> = {
  serviceDisabled: 'Turn on Location / GPS in system settings, then try again',
  permissionDenied: 'Allow location access when prompted, then try again',
  permissionDeniedForever: 'Location permission is blocked — enable it in app settings',
  unavailable: 'Couldn’t read GPS — move outdoors or try again in a moment',
};

let prompted = false;

export async function ensurePermissionOnStartup(): Promise<boolean> {
  if (prompted) {
    const existing = await Location.getForegroundPermissionsAsync();
    return existing.granted;
  }
  prompted = true;
  try {
    const existing = await Location.getForegroundPermissionsAsync();
    if (existing.granted) return true;
    const asked = await Location.requestForegroundPermissionsAsync();
    return asked.granted;
  } catch {
    return false;
  }
}

export async function currentPositionDetailed(): Promise<LocationResult> {
  try {
    const enabled = await Location.hasServicesEnabledAsync();
    if (!enabled) return { ok: false, failure: 'serviceDisabled', message: messages.serviceDisabled };
    const existing = await Location.getForegroundPermissionsAsync();
    let status = existing;
    if (!status.granted) {
      status = await Location.requestForegroundPermissionsAsync();
    }
    if (!status.granted) {
      const forever = status.canAskAgain === false;
      return {
        ok: false,
        failure: forever ? 'permissionDeniedForever' : 'permissionDenied',
        message: forever ? messages.permissionDeniedForever : messages.permissionDenied,
      };
    }
    const pos = await Location.getCurrentPositionAsync({ accuracy: Location.Accuracy.High });
    return { ok: true, lat: pos.coords.latitude, lng: pos.coords.longitude };
  } catch {
    try {
      const last = await Location.getLastKnownPositionAsync();
      if (last) return { ok: true, lat: last.coords.latitude, lng: last.coords.longitude };
    } catch {
      /* ignore */
    }
    return { ok: false, failure: 'unavailable', message: messages.unavailable };
  }
}
