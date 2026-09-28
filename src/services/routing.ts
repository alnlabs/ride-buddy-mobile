import axios from 'axios';

import { DriveRoute, parseDriveRoute } from '@/src/models/types';
import { api } from '@/src/services/api';

function durationLabel(seconds: number): string {
  const mins = Math.round(seconds / 60);
  if (mins < 60) return `${mins} min`;
  const h = Math.floor(mins / 60);
  const m = mins % 60;
  return m === 0 ? `${h}h` : `${h}h ${m}m`;
}

function distanceLabel(meters: number): string {
  const km = meters / 1000;
  return km >= 10 ? `${km.toFixed(0)} km` : `${km.toFixed(1)} km`;
}

export function routeChipLabel(route: DriveRoute): string {
  const rank = route.index === 0 ? 'Fastest' : route.index === 1 ? '2nd' : route.index === 2 ? '3rd' : `Alt ${route.index + 1}`;
  const delay = route.trafficDelaySeconds > 60 ? ` · +${Math.round(route.trafficDelaySeconds / 60)} min traffic` : route.usesLiveTraffic ? ' · live' : '';
  return `${rank} · ${durationLabel(route.durationSeconds)} · ${distanceLabel(route.distanceMeters)}${delay}`;
}

export async function fetchDriveRoutes(
  from: { lat: number; lng: number },
  to: { lat: number; lng: number },
): Promise<DriveRoute[]> {
  try {
    const res = await api.post('/routes/drive', {
      fromLat: from.lat,
      fromLng: from.lng,
      toLat: to.lat,
      toLng: to.lng,
    });
    const list = Array.isArray(res.data) ? res.data : res.data?.routes;
    if (Array.isArray(list) && list.length) {
      return list.map((r, i) => ({ ...parseDriveRoute(r as Record<string, unknown>), index: i }));
    }
  } catch {
    /* fall through to OSRM */
  }

  try {
    const url = `https://router.project-osrm.org/route/v1/driving/${from.lng},${from.lat};${to.lng},${to.lat}`;
    const res = await axios.get(url, { params: { overview: 'full', geometries: 'geojson', alternatives: true } });
    const routes = (res.data?.routes as unknown[]) ?? [];
    return routes.slice(0, 3).map((r, i) => {
      const row = r as { distance?: number; duration?: number; geometry?: { coordinates?: number[][] } };
      const coords = row.geometry?.coordinates ?? [];
      return {
        points: coords.map((c) => ({ latitude: Number(c[1]), longitude: Number(c[0]) })),
        distanceMeters: Number(row.distance ?? 0),
        durationSeconds: Number(row.duration ?? 0),
        trafficDelaySeconds: 0,
        usesLiveTraffic: false,
        index: i,
        viaLabel: null,
      };
    });
  } catch {
    return [];
  }
}
