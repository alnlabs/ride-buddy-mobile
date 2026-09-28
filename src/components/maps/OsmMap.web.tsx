import { useEffect, useId, useRef } from 'react';
import { View } from 'react-native';

import { colors } from '@/src/theme/colors';

export type MapPoint = { latitude: number; longitude: number; title?: string; color?: string };
export type MapRoute = { points: { latitude: number; longitude: number }[]; color?: string; width?: number };

type Props = {
  height?: number;
  flex?: boolean;
  center?: { latitude: number; longitude: number };
  points?: MapPoint[];
  route?: { latitude: number; longitude: number }[];
  routes?: MapRoute[];
};

type Leaflet = {
  map: (el: HTMLElement, opts?: object) => LeafletMap;
  tileLayer: (url: string, opts?: object) => { addTo: (map: LeafletMap) => void };
  layerGroup: () => LeafletLayer;
  polyline: (latlngs: [number, number][], opts?: object) => { addTo: (layer: LeafletLayer) => void };
  circleMarker: (latlng: [number, number], opts?: object) => { bindTooltip?: (t: string) => { addTo: (layer: LeafletLayer) => void }; addTo: (layer: LeafletLayer) => void };
  latLngBounds: (latlngs: [number, number][]) => { pad: (n: number) => unknown };
};

type LeafletMap = {
  remove: () => void;
  invalidateSize: () => void;
  fitBounds: (bounds: unknown, opts?: object) => void;
  setView: (center: [number, number], zoom: number) => void;
};

type LeafletLayer = {
  addTo: (map: LeafletMap) => LeafletLayer;
  remove: () => void;
  clearLayers: () => void;
};

const HYD: [number, number] = [17.385, 78.4867];

let leafletLoader: Promise<Leaflet> | null = null;

function loadLeaflet(): Promise<Leaflet> {
  if (typeof window === 'undefined') return Promise.reject(new Error('no window'));
  const existing = (window as unknown as { L?: Leaflet }).L;
  if (existing) return Promise.resolve(existing);
  if (leafletLoader) return leafletLoader;
  leafletLoader = new Promise((resolve, reject) => {
    if (!document.querySelector('link[data-rb-leaflet]')) {
      const link = document.createElement('link');
      link.rel = 'stylesheet';
      link.href = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.css';
      link.setAttribute('data-rb-leaflet', '1');
      document.head.appendChild(link);
    }
    const script = document.createElement('script');
    script.src = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.js';
    script.async = true;
    script.onload = () => {
      const L = (window as unknown as { L?: Leaflet }).L;
      if (L) resolve(L);
      else reject(new Error('Leaflet missing'));
    };
    script.onerror = () => reject(new Error('Leaflet failed'));
    document.body.appendChild(script);
  });
  return leafletLoader;
}

function paint(
  L: Leaflet,
  map: LeafletMap,
  layer: LeafletLayer,
  points: MapPoint[],
  route: { latitude: number; longitude: number }[],
  routes: MapRoute[] | undefined,
  center?: { latitude: number; longitude: number },
) {
  layer.clearLayers();
  const lines: MapRoute[] = routes?.length
    ? routes
    : route.length >= 2
      ? [{ points: route, color: colors.brandBlue, width: 4 }]
      : [];
  const bounds: [number, number][] = [];

  for (const line of lines) {
    if (line.points.length < 2) continue;
    const latlngs = line.points.map((p) => [p.latitude, p.longitude] as [number, number]);
    L.polyline(latlngs, {
      color: line.color ?? colors.brandBlue,
      weight: line.width ?? 4,
      opacity: 0.9,
    }).addTo(layer);
    bounds.push(...latlngs);
  }

  points.forEach((p, i) => {
    const color = p.color ?? (i === 0 ? colors.brandBlue : colors.brandOrange);
    const marker = L.circleMarker([p.latitude, p.longitude], {
      radius: 8,
      color: '#fff',
      weight: 2,
      fillColor: color,
      fillOpacity: 1,
    });
    if (p.title && marker.bindTooltip) marker.bindTooltip(p.title);
    marker.addTo(layer);
    bounds.push([p.latitude, p.longitude]);
  });

  if (bounds.length >= 2) {
    map.fitBounds(L.latLngBounds(bounds).pad(0.18), { animate: false });
  } else if (bounds.length === 1) {
    map.setView(bounds[0], 14);
  } else if (center) {
    map.setView([center.latitude, center.longitude], 12);
  } else {
    map.setView(HYD, 11);
  }
  map.invalidateSize();
}

export function OsmMap({ height = 220, flex, center, points = [], route = [], routes }: Props) {
  const rawId = useId().replace(/:/g, '');
  const boxId = `rb-map-${rawId}`;
  const mapRef = useRef<LeafletMap | null>(null);
  const layerRef = useRef<LeafletLayer | null>(null);
  const leafletRef = useRef<Leaflet | null>(null);
  const latest = useRef({ points, route, routes, center });
  latest.current = { points, route, routes, center };

  useEffect(() => {
    let cancelled = false;
    let map: LeafletMap | null = null;
    loadLeaflet()
      .then((L) => {
        if (cancelled) return;
        const el = document.getElementById(boxId);
        if (!el) return;
        leafletRef.current = L;
        map = L.map(el, { zoomControl: false, attributionControl: true });
        L.tileLayer('https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png', {
          maxZoom: 19,
          attribution: '&copy; OpenStreetMap &copy; CARTO',
        }).addTo(map);
        const layer = L.layerGroup().addTo(map);
        mapRef.current = map;
        layerRef.current = layer;
        const snap = latest.current;
        paint(L, map, layer, snap.points, snap.route, snap.routes, snap.center);
        requestAnimationFrame(() => map?.invalidateSize());
      })
      .catch(() => undefined);
    return () => {
      cancelled = true;
      map?.remove();
      mapRef.current = null;
      layerRef.current = null;
    };
  }, [boxId]);

  useEffect(() => {
    const L = leafletRef.current;
    const map = mapRef.current;
    const layer = layerRef.current;
    if (!L || !map || !layer) return;
    paint(L, map, layer, points, route, routes, center);
  }, [center, points, route, routes]);

  return (
    <View
      style={{
        height: flex ? undefined : height,
        flex: flex ? 1 : undefined,
        borderRadius: flex ? 0 : 20,
        overflow: 'hidden',
        backgroundColor: colors.skyMid,
        borderWidth: flex ? 0 : 1,
        borderColor: colors.line,
      }}>
      <div id={boxId} style={{ width: '100%', height: '100%', minHeight: flex ? 0 : height }} />
    </View>
  );
}
