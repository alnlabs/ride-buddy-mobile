const NOISE = new Set([
  'india',
  'bharat',
  'telangana',
  'andhra pradesh',
  'karnataka',
  'tamil nadu',
  'maharashtra',
  'delhi',
  'nct',
]);

function firstNonEmpty(values: (string | null | undefined)[]): string | undefined {
  for (const v of values) {
    const t = v?.trim();
    if (t) return t;
  }
  return undefined;
}

function same(a?: string, b?: string): boolean {
  return !!a && !!b && a.trim().toLowerCase() === b.trim().toLowerCase();
}

export function shortenStoredLabel(label: string, max = 48): string {
  const parts = label
    .split(',')
    .map((p) => p.trim())
    .filter((p) => p && !NOISE.has(p.toLowerCase()));
  const short = parts.slice(0, 3).join(', ');
  if (short.length <= max) return short || label;
  return `${short.slice(0, max - 1)}…`;
}

export function fromNominatim(opts: {
  address?: Record<string, unknown> | null;
  name?: string | null;
  displayName?: string | null;
}): string {
  const address = opts.address ?? {};
  const landmark = firstNonEmpty([
    opts.name,
    address.amenity as string,
    address.building as string,
    address.tourism as string,
    address.shop as string,
    address.office as string,
    address.leisure as string,
  ]);
  const road = firstNonEmpty([
    address.road as string,
    address.pedestrian as string,
    address.residential as string,
  ]);
  const area = firstNonEmpty([
    address.suburb as string,
    address.neighbourhood as string,
    address.neighborhood as string,
    address.quarter as string,
    address.city_district as string,
    address.village as string,
    address.hamlet as string,
    address.locality as string,
  ]);
  const city = firstNonEmpty([
    address.city as string,
    address.town as string,
    address.municipality as string,
    address.county as string,
  ]);

  const parts: string[] = [];
  if (landmark) {
    parts.push(landmark);
    if (area && !same(area, landmark)) parts.push(area);
    if (city && !same(city, landmark) && !same(city, area) && parts.length < 3) parts.push(city);
  } else if (road) {
    parts.push(road);
    if (area && !same(area, road)) parts.push(area);
    if (city && !same(city, road) && !same(city, area) && parts.length < 3) parts.push(city);
  } else if (area) {
    parts.push(area);
    if (city && !same(city, area)) parts.push(city);
  } else if (city) {
    parts.push(city);
  }

  if (parts.length) return parts.slice(0, 3).join(', ');
  return shortenStoredLabel(opts.displayName ?? opts.name ?? 'Unknown');
}

export function fromPhoton(props: Record<string, unknown>): string {
  return fromNominatim({
    name: props.name as string,
    displayName: [props.name, props.street, props.district, props.city].filter(Boolean).join(', '),
    address: {
      road: props.street,
      suburb: props.district,
      city: props.city,
    },
  });
}

export function cityFromNominatim(address?: Record<string, unknown> | null): string | undefined {
  if (!address) return undefined;
  return firstNonEmpty([
    address.city as string,
    address.town as string,
    address.municipality as string,
    address.county as string,
  ]);
}
