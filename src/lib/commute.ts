import { Profile, Ride } from '@/src/models/types';

export function greetingFor(name: string): string {
  const hour = new Date().getHours();
  const hello = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
  const trimmed = name.trim() || 'there';
  return `${hello}, ${trimmed}`;
}

export function isEveningCommute(date = new Date()): boolean {
  return date.getHours() >= 15;
}

export function hasSavedCommute(profile?: Profile | null): boolean {
  if (!profile) return false;
  return profile.homeLat != null && profile.homeLng != null && profile.officeLat != null && profile.officeLng != null;
}

export function routeMatchPercent(ride: Ride): number {
  if (ride.detourKm != null && Number.isFinite(ride.detourKm)) {
    return Math.max(42, Math.min(99, Math.round(100 - ride.detourKm * 6)));
  }
  switch (ride.commuteMatchType) {
    case 'same_route':
      return 92;
    case 'same_destination':
      return 84;
    case 'same_origin':
      return 80;
    case 'partial':
      return 72;
    case 'nearby':
      return 68;
    default:
      return 70;
  }
}

export function matchLabel(percent: number): string {
  if (percent >= 80) return 'Great route match';
  if (percent >= 65) return 'Good route match';
  return 'Nearby route';
}

export function arrivalFrom(depart: Date, durationSeconds?: number | null): Date {
  const extra = durationSeconds && durationSeconds > 0 ? durationSeconds * 1000 : 45 * 60 * 1000;
  return new Date(depart.getTime() + extra);
}

export function formatKm(km: number): string {
  return km >= 10 ? `${km.toFixed(0)} km` : `${km.toFixed(1)} km`;
}

export function durationLabel(seconds: number): string {
  const mins = Math.round(seconds / 60);
  if (mins < 60) return `${mins} min`;
  const h = Math.floor(mins / 60);
  const m = mins % 60;
  return m === 0 ? `${h}h` : `${h}h ${m}m`;
}

export function distanceLabel(meters: number): string {
  return formatKm(meters / 1000);
}

export function profileCompletion(profile: Profile, phone?: string | null) {
  const items = [
    { key: 'photo', label: 'Profile photo', done: Boolean(profile.avatarUrl) },
    { key: 'name', label: 'Name', done: Boolean(profile.displayName?.trim()) },
    { key: 'phone', label: 'Phone verified', done: Boolean(phone?.trim()) },
    { key: 'email', label: 'Email verification', done: profile.employeeVerified || Boolean(profile.contactEmail) },
    { key: 'city', label: 'City', done: Boolean(profile.officeLabel || profile.homeLabel) },
    { key: 'interests', label: 'Interests', done: profile.interests.length >= 5 },
    { key: 'home', label: 'Home', done: profile.homeLat != null },
    { key: 'office', label: 'Office', done: profile.officeLat != null },
    { key: 'about', label: 'About', done: Boolean(profile.experienceBio?.trim()) },
  ] as const;
  const done = items.filter((item) => item.done).length;
  return { items, percent: Math.round((done / items.length) * 100) };
}
