import axios from 'axios';
import { Platform } from 'react-native';

import { PlaceSuggestion } from '@/src/models/types';
import { cityFromNominatim, fromNominatim, fromPhoton, shortenStoredLabel } from '@/src/services/placeLabel';

export const kMaxLocalSearchKm = 100;

/** Browsers forbid setting User-Agent; native still identifies the app to Nominatim. */
function geoHeaders(agent: string): Record<string, string> {
  const headers: Record<string, string> = { Accept: 'application/json' };
  if (Platform.OS !== 'web') headers['User-Agent'] = agent;
  return headers;
}

const nominatim = axios.create({
  baseURL: 'https://nominatim.openstreetmap.org',
  timeout: 12000,
  headers: geoHeaders('RideBuddy/1.0 (com.alnlabs.ridebuddy; +https://alnlabs.com)'),
  validateStatus: (code) => code >= 200 && code < 500,
});

const photon = axios.create({
  baseURL: 'https://photon.komoot.io',
  timeout: 12000,
  headers: geoHeaders('RideBuddy/1.0 (com.alnlabs.ridebuddy)'),
});

export function haversineKm(aLat: number, aLng: number, bLat: number, bLng: number): number {
  const toRad = (d: number) => (d * Math.PI) / 180;
  const dLat = toRad(bLat - aLat);
  const dLng = toRad(bLng - aLng);
  const s =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(aLat)) * Math.cos(toRad(bLat)) * Math.sin(dLng / 2) ** 2;
  return 6371 * 2 * Math.atan2(Math.sqrt(s), Math.sqrt(1 - s));
}

export function withinLocalTrip(aLat: number, aLng: number, bLat: number, bLng: number): boolean {
  return haversineKm(aLat, aLng, bLat, bLng) <= kMaxLocalSearchKm;
}

function dedupe(places: PlaceSuggestion[]): PlaceSuggestion[] {
  const seen = new Set<string>();
  const out: PlaceSuggestion[] = [];
  for (const p of places) {
    const key = `${p.publicShort}|${p.lat.toFixed(4)}|${p.lng.toFixed(4)}`;
    if (seen.has(key)) continue;
    seen.add(key);
    out.push(p);
  }
  return out;
}

async function searchNominatim(
  query: string,
  nearLat?: number,
  nearLng?: number,
  appendCity?: string,
): Promise<PlaceSuggestion[]> {
  const q = appendCity ? `${query}, ${appendCity}` : query;
  const params: Record<string, string | number> = {
    q,
    format: 'jsonv2',
    addressdetails: 1,
    limit: 8,
    countrycodes: 'in',
  };
  if (nearLat != null && nearLng != null) {
    const d = 0.9;
    params.viewbox = `${nearLng - d},${nearLat + d},${nearLng + d},${nearLat - d}`;
    params.bounded = 0;
  }
  const res = await nominatim.get('/search', { params });
  if (!Array.isArray(res.data)) return [];
  return res.data.map((row: Record<string, unknown>) => {
    const address = (row.address as Record<string, unknown>) ?? {};
    return {
      publicShort: fromNominatim({
        address,
        name: row.name as string,
        displayName: row.display_name as string,
      }),
      fullAddress: (row.display_name as string) ?? null,
      lat: Number(row.lat),
      lng: Number(row.lon),
      city: cityFromNominatim(address),
    };
  });
}

async function searchPhoton(query: string, nearLat?: number, nearLng?: number): Promise<PlaceSuggestion[]> {
  const params: Record<string, string | number> = { q: query, limit: 8, lang: 'en' };
  if (nearLat != null && nearLng != null) {
    params.lat = nearLat;
    params.lon = nearLng;
  }
  const res = await photon.get('/api', { params });
  const features = (res.data?.features as unknown[]) ?? [];
  const out: PlaceSuggestion[] = [];
  for (const f of features) {
    const feat = f as { geometry?: { coordinates?: number[] }; properties?: Record<string, unknown> };
    const coords = feat.geometry?.coordinates;
    if (!coords || coords.length < 2) continue;
    const props = feat.properties ?? {};
    out.push({
      publicShort: fromPhoton(props),
      fullAddress: [props.name, props.street, props.city, props.country].filter(Boolean).join(', '),
      lat: Number(coords[1]),
      lng: Number(coords[0]),
      city: (props.city as string) ?? null,
    });
  }
  return out;
}

export async function searchPlaces(
  query: string,
  opts?: { city?: string | null; nearLat?: number | null; nearLng?: number | null },
): Promise<PlaceSuggestion[]> {
  const q = query.trim();
  if (q.length < 2) return [];
  const nearLat = opts?.nearLat ?? undefined;
  const nearLng = opts?.nearLng ?? undefined;
  try {
    const chunks = await Promise.all([
      searchNominatim(q, nearLat, nearLng),
      searchPhoton(q, nearLat, nearLng),
      opts?.city ? searchNominatim(q, nearLat, nearLng, opts.city) : Promise.resolve([]),
    ]);
    let merged = dedupe(chunks.flat());
    if (nearLat != null && nearLng != null) {
      merged = merged.filter((p) => haversineKm(nearLat, nearLng, p.lat, p.lng) <= kMaxLocalSearchKm);
    }
    return merged.slice(0, 12);
  } catch {
    return [];
  }
}

export async function reverseDetailed(lat: number, lng: number): Promise<PlaceSuggestion | null> {
  try {
    const res = await nominatim.get('/reverse', {
      params: { lat, lon: lng, format: 'jsonv2', addressdetails: 1 },
    });
    const row = res.data as Record<string, unknown>;
    if (!row || row.error) return null;
    const address = (row.address as Record<string, unknown>) ?? {};
    return {
      publicShort: fromNominatim({
        address,
        name: row.name as string,
        displayName: row.display_name as string,
      }),
      fullAddress: (row.display_name as string) ?? null,
      lat,
      lng,
      city: cityFromNominatim(address),
    };
  } catch {
    return {
      publicShort: 'Current location',
      fullAddress: `${lat.toFixed(5)}, ${lng.toFixed(5)}`,
      lat,
      lng,
    };
  }
}

export function shortenLabel(label: string, max = 28): string {
  return shortenStoredLabel(label, max);
}
