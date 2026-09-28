export type PosterCard = {
  userId: string;
  displayName: string;
  jobRole?: string | null;
  company?: string | null;
  topInterests: string[];
  employeeVerified: boolean;
};

export type Profile = {
  userId: string;
  displayName: string;
  avatarUrl?: string | null;
  homeLat?: number | null;
  homeLng?: number | null;
  homeLabel?: string | null;
  officeLat?: number | null;
  officeLng?: number | null;
  officeLabel?: string | null;
  experienceBio?: string | null;
  canOfferRides: boolean;
  profileStrength: number;
  jobRole?: string | null;
  company?: string | null;
  contactEmail?: string | null;
  officeEmail?: string | null;
  officeEmailStatus: string;
  employeeVerified: boolean;
  interests: string[];
  topInterests: string[];
};

export type Vehicle = {
  id: string;
  nickname?: string | null;
  makeModel: string;
  plateMasked: string;
  plateNumber?: string | null;
  seats: number;
  color?: string | null;
  primary: boolean;
  active: boolean;
};

export type Ride = {
  id: string;
  ownerId: string;
  vehicleId: string;
  status: string;
  comfortRide: boolean;
  originLat: number;
  originLng: number;
  originLabel: string;
  originFullAddress?: string | null;
  originPrivateLabel?: string | null;
  destinationLat: number;
  destinationLng: number;
  destinationLabel: string;
  destinationFullAddress?: string | null;
  destinationPrivateLabel?: string | null;
  departAt: Date;
  expiresAt?: Date | null;
  availableSeats: number;
  pricePerSeat: number;
  recurring: boolean;
  scheduleId?: string | null;
  commuteMatchType?: string | null;
  detourKm?: number | null;
  routeGeometry?: number[][] | null;
  routeDistanceM?: number | null;
  routeDurationS?: number | null;
  poster?: PosterCard | null;
};

export type Booking = {
  id: string;
  rideId: string;
  status: string;
  seatsRequested: number;
  amount: number;
  paymentMethod: string;
  pickupLabel?: string | null;
  dropLabel?: string | null;
  rideOriginLabel?: string | null;
  rideDestinationLabel?: string | null;
  departAt?: Date | null;
};

export type RideRequest = {
  id: string;
  requesterId: string;
  originLat: number;
  originLng: number;
  originLabel: string;
  originFullAddress?: string | null;
  originPrivateLabel?: string | null;
  destinationLat: number;
  destinationLng: number;
  destinationLabel: string;
  destinationFullAddress?: string | null;
  destinationPrivateLabel?: string | null;
  departAt: Date;
  expiresAt?: Date | null;
  seatsNeeded: number;
  comfortPreferred: boolean;
  status: string;
  recurring: boolean;
  scheduleId?: string | null;
  matchedRideId?: string | null;
  matchedBookingId?: string | null;
  poster?: PosterCard | null;
};

export type SavedPlace = {
  id: string;
  kind: 'home' | 'office' | string;
  privateLabel: string;
  publicShort: string;
  fullAddress?: string | null;
  lat: number;
  lng: number;
  primary: boolean;
};

export type RideOffer = {
  id: string;
  requestId: string;
  rideId: string;
  ownerId: string;
  status: string;
  request?: RideRequest | null;
  ride?: Ride | null;
};

export type NeedInboxItem = {
  request: RideRequest;
  suggestedRideId: string;
  detourKm: number;
  alreadyOffered: boolean;
};

export type RideSchedule = {
  id: string;
  kind: string;
  frequency: string;
  daysOfWeek: number[];
  dayOfMonth?: number | null;
  departLocalTime: string;
  timezone: string;
  active: boolean;
  vehicleId?: string | null;
  originLabel: string;
  destinationLabel: string;
};

export type ChatConversation = {
  id: string;
  rideId: string;
  hostId: string;
  coRiderId: string;
  bookingId?: string | null;
  offerId?: string | null;
  rideOriginLabel?: string | null;
  rideDestinationLabel?: string | null;
  departAt?: Date | null;
  myRole: string;
  peer: PosterCard;
  lastMessagePreview?: string | null;
  lastMessageAt?: Date | null;
  unreadCount: number;
  canSend: boolean;
};

export type ChatMessage = {
  id: string;
  conversationId: string;
  senderId: string;
  body: string;
  createdAt: Date;
};

export type PlaceSuggestion = {
  publicShort: string;
  fullAddress?: string | null;
  privateLabel?: string | null;
  lat: number;
  lng: number;
  city?: string | null;
  savedPlaceId?: string | null;
  kind?: string | null;
};

export type DriveRoute = {
  points: { latitude: number; longitude: number }[];
  distanceMeters: number;
  durationSeconds: number;
  trafficDelaySeconds: number;
  index: number;
  usesLiveTraffic: boolean;
  viaLabel?: string | null;
};

export type TripGuidelines = {
  phase: string;
  role: string;
  heading: string;
  intro: string;
  common: { title: string; body: string }[];
  expectations: { title: string; body: string }[];
  conversationHints: { interest: string; suggestion: string }[];
  sharedInterests: string[];
  partnerDisplayName?: string | null;
  viewerHasInterests: boolean;
  partnerHasInterests: boolean;
};

export type HomeSpotlight = {
  id: string;
  kind: 'tip' | 'quote';
  title: string;
  body: string;
  category?: string;
  author?: string;
  ctaLabel?: string;
  ctaRoute?: string;
  icon: string;
};

export function workLine(jobRole?: string | null, company?: string | null): string | undefined {
  const parts = [jobRole?.trim(), company?.trim()].filter(Boolean) as string[];
  return parts.length ? parts.join(' · ') : undefined;
}

export function profileWorkLine(p: Profile): string | undefined {
  return workLine(p.jobRole, p.company);
}

export function emailSetupSubtitle(p: Profile): string {
  if (p.employeeVerified) return `Verified employee · ${p.officeEmail ?? ''}`;
  if (p.officeEmailStatus === 'pending') return 'Office email pending · enter code';
  if (p.contactEmail) return `Personal: ${p.contactEmail}`;
  return 'Verify office email · personal Gmail optional';
}

export function vehicleDisplayName(v: Vehicle): string {
  return v.nickname?.trim() ? v.nickname : v.makeModel;
}

export function placeFieldLabel(p: PlaceSuggestion): string {
  if (p.kind === 'home' || p.kind === 'office') {
    const pub = p.publicShort.trim();
    if (pub && pub.toLowerCase() !== 'home' && pub.toLowerCase() !== 'office') return pub;
  }
  return p.privateLabel?.trim() || p.publicShort;
}

export function originTitle(item: Pick<Ride, 'originLabel' | 'originPrivateLabel'>, isOwner: boolean): string {
  if (isOwner && item.originPrivateLabel?.trim()) return item.originPrivateLabel.trim();
  return item.originLabel;
}

export function destinationTitle(
  item: Pick<Ride, 'destinationLabel' | 'destinationPrivateLabel'>,
  isOwner: boolean,
): string {
  if (isOwner && item.destinationPrivateLabel?.trim()) return item.destinationPrivateLabel.trim();
  return item.destinationLabel;
}

export function frequencyLabel(frequency: string): string {
  switch (frequency) {
    case 'daily':
      return 'Daily';
    case 'weekdays':
      return 'Weekdays';
    case 'weekends':
      return 'Weekends';
    case 'weekly':
      return 'Weekly';
    case 'monthly':
      return 'Monthly';
    case 'custom_days':
      return 'Specific days';
    default:
      return frequency;
  }
}

function asDate(value: unknown): Date | undefined {
  if (!value) return undefined;
  return new Date(String(value));
}

function parseGeometry(raw: unknown): number[][] | null {
  let coords: unknown[] | null = null;
  if (Array.isArray(raw)) coords = raw;
  else if (typeof raw === 'string' && raw.trim()) {
    try {
      const decoded = JSON.parse(raw);
      if (Array.isArray(decoded)) coords = decoded;
    } catch {
      return null;
    }
  }
  if (!coords) return null;
  const geometry = coords
    .filter((e): e is unknown[] => Array.isArray(e) && e.length >= 2)
    .map((e) => [Number(e[0]), Number(e[1])]);
  return geometry.length >= 2 ? geometry : null;
}

function parsePoster(j: unknown): PosterCard | null {
  if (!j || typeof j !== 'object') return { userId: '', displayName: 'Rider', topInterests: [], employeeVerified: false };
  const m = j as Record<string, unknown>;
  return {
    userId: String(m.userId ?? ''),
    displayName: String(m.displayName ?? 'Rider'),
    jobRole: (m.jobRole as string) ?? null,
    company: (m.company as string) ?? null,
    topInterests: Array.isArray(m.topInterests) ? m.topInterests.map(String) : [],
    employeeVerified: Boolean(m.employeeVerified),
  };
}

export function parseProfile(j: Record<string, unknown>): Profile {
  const interests = Array.isArray(j.interests) ? j.interests.map(String) : [];
  const top = Array.isArray(j.topInterests) ? j.topInterests.map(String) : interests.slice(0, 5);
  return {
    userId: String(j.userId),
    displayName: String(j.displayName ?? 'Rider'),
    avatarUrl: (j.avatarUrl as string) ?? null,
    homeLat: j.homeLat != null ? Number(j.homeLat) : null,
    homeLng: j.homeLng != null ? Number(j.homeLng) : null,
    homeLabel: (j.homeLabel as string) ?? null,
    officeLat: j.officeLat != null ? Number(j.officeLat) : null,
    officeLng: j.officeLng != null ? Number(j.officeLng) : null,
    officeLabel: (j.officeLabel as string) ?? null,
    experienceBio: (j.experienceBio as string) ?? null,
    canOfferRides: Boolean(j.canOfferRides),
    profileStrength: Number(j.profileStrength ?? 0),
    jobRole: (j.jobRole as string) ?? null,
    company: (j.company as string) ?? null,
    contactEmail: (j.contactEmail as string) ?? null,
    officeEmail: (j.officeEmail as string) ?? null,
    officeEmailStatus: String(j.officeEmailStatus ?? 'none'),
    employeeVerified: Boolean(j.employeeVerified),
    interests,
    topInterests: top,
  };
}

export function parseVehicle(j: Record<string, unknown>): Vehicle {
  return {
    id: String(j.id),
    nickname: (j.nickname as string) ?? null,
    makeModel: String(j.makeModel),
    plateMasked: String(j.plateMasked ?? '****'),
    plateNumber: (j.plateNumber as string) ?? null,
    seats: Number(j.seats),
    color: (j.color as string) ?? null,
    primary: Boolean(j.primary),
    active: j.active !== false,
  };
}

export function parseRide(j: Record<string, unknown>): Ride {
  return {
    id: String(j.id),
    ownerId: String(j.ownerId),
    vehicleId: String(j.vehicleId),
    status: String(j.status),
    comfortRide: Boolean(j.comfortRide),
    originLat: Number(j.originLat),
    originLng: Number(j.originLng),
    originLabel: String(j.originLabel),
    originFullAddress: (j.originFullAddress as string) ?? null,
    originPrivateLabel: (j.originPrivateLabel as string) ?? null,
    destinationLat: Number(j.destinationLat),
    destinationLng: Number(j.destinationLng),
    destinationLabel: String(j.destinationLabel),
    destinationFullAddress: (j.destinationFullAddress as string) ?? null,
    destinationPrivateLabel: (j.destinationPrivateLabel as string) ?? null,
    departAt: new Date(String(j.departAt)),
    expiresAt: asDate(j.expiresAt) ?? null,
    availableSeats: Number(j.availableSeats),
    pricePerSeat: Number(j.pricePerSeat),
    recurring: Boolean(j.recurring),
    scheduleId: (j.scheduleId as string) ?? null,
    commuteMatchType: (j.commuteMatchType as string) ?? null,
    detourKm: j.detourKm != null ? Number(j.detourKm) : null,
    routeGeometry: parseGeometry(j.routeGeometry),
    routeDistanceM: j.routeDistanceM != null ? Number(j.routeDistanceM) : null,
    routeDurationS: j.routeDurationS != null ? Number(j.routeDurationS) : null,
    poster: j.poster && typeof j.poster === 'object' ? parsePoster(j.poster) : null,
  };
}

export function parseBooking(j: Record<string, unknown>): Booking {
  return {
    id: String(j.id),
    rideId: String(j.rideId),
    status: String(j.status),
    seatsRequested: Number(j.seatsRequested),
    amount: Number(j.amount),
    paymentMethod: String(j.paymentMethod ?? 'cash'),
    pickupLabel: (j.pickupLabel as string) ?? null,
    dropLabel: (j.dropLabel as string) ?? null,
    rideOriginLabel: (j.rideOriginLabel as string) ?? null,
    rideDestinationLabel: (j.rideDestinationLabel as string) ?? null,
    departAt: asDate(j.departAt) ?? null,
  };
}

export function parseNeed(j: Record<string, unknown>): RideRequest {
  return {
    id: String(j.id),
    requesterId: String(j.requesterId),
    originLat: Number(j.originLat),
    originLng: Number(j.originLng),
    originLabel: String(j.originLabel),
    originFullAddress: (j.originFullAddress as string) ?? null,
    originPrivateLabel: (j.originPrivateLabel as string) ?? null,
    destinationLat: Number(j.destinationLat),
    destinationLng: Number(j.destinationLng),
    destinationLabel: String(j.destinationLabel),
    destinationFullAddress: (j.destinationFullAddress as string) ?? null,
    destinationPrivateLabel: (j.destinationPrivateLabel as string) ?? null,
    departAt: new Date(String(j.departAt)),
    expiresAt: asDate(j.expiresAt) ?? null,
    seatsNeeded: Number(j.seatsNeeded ?? 1),
    comfortPreferred: Boolean(j.comfortPreferred),
    status: String(j.status),
    recurring: Boolean(j.recurring),
    scheduleId: (j.scheduleId as string) ?? null,
    matchedRideId: (j.matchedRideId as string) ?? null,
    matchedBookingId: (j.matchedBookingId as string) ?? null,
    poster: j.poster && typeof j.poster === 'object' ? parsePoster(j.poster) : null,
  };
}

export function parseSavedPlace(j: Record<string, unknown>): SavedPlace {
  return {
    id: String(j.id),
    kind: String(j.kind),
    privateLabel: String(j.privateLabel),
    publicShort: String(j.publicShort),
    fullAddress: (j.fullAddress as string) ?? null,
    lat: Number(j.lat),
    lng: Number(j.lng),
    primary: Boolean(j.primary),
  };
}

export function parseOffer(j: Record<string, unknown>): RideOffer {
  return {
    id: String(j.id),
    requestId: String(j.requestId),
    rideId: String(j.rideId),
    ownerId: String(j.ownerId),
    status: String(j.status),
    request: j.request && typeof j.request === 'object' ? parseNeed(j.request as Record<string, unknown>) : null,
    ride: j.ride && typeof j.ride === 'object' ? parseRide(j.ride as Record<string, unknown>) : null,
  };
}

export function parseInboxItem(j: Record<string, unknown>): NeedInboxItem {
  return {
    request: parseNeed(j.request as Record<string, unknown>),
    suggestedRideId: String(j.suggestedRideId),
    detourKm: Number(j.detourKm),
    alreadyOffered: Boolean(j.alreadyOffered),
  };
}

export function parseSchedule(j: Record<string, unknown>): RideSchedule {
  const time = String(j.departLocalTime ?? '');
  return {
    id: String(j.id),
    kind: String(j.kind),
    frequency: String(j.frequency),
    daysOfWeek: Array.isArray(j.daysOfWeek) ? j.daysOfWeek.map(Number) : [],
    dayOfMonth: j.dayOfMonth != null ? Number(j.dayOfMonth) : null,
    departLocalTime: time.length >= 5 ? time.slice(0, 5) : time,
    timezone: String(j.timezone ?? 'Asia/Kolkata'),
    active: j.active !== false,
    vehicleId: (j.vehicleId as string) ?? null,
    originLabel: String(j.originLabel ?? 'Origin'),
    destinationLabel: String(j.destinationLabel ?? 'Destination'),
  };
}

export function parseConversation(j: Record<string, unknown>): ChatConversation {
  return {
    id: String(j.id),
    rideId: String(j.rideId),
    hostId: String(j.hostId),
    coRiderId: String(j.coRiderId),
    bookingId: (j.bookingId as string) ?? null,
    offerId: (j.offerId as string) ?? null,
    rideOriginLabel: (j.rideOriginLabel as string) ?? null,
    rideDestinationLabel: (j.rideDestinationLabel as string) ?? null,
    departAt: asDate(j.departAt) ?? null,
    myRole: String(j.myRole ?? 'co_rider'),
    peer: parsePoster(j.peer) ?? { userId: '', displayName: 'Rider', topInterests: [], employeeVerified: false },
    lastMessagePreview: (j.lastMessagePreview as string) ?? null,
    lastMessageAt: asDate(j.lastMessageAt) ?? null,
    unreadCount: Number(j.unreadCount ?? 0),
    canSend: j.canSend !== false,
  };
}

export function parseMessage(j: Record<string, unknown>): ChatMessage {
  return {
    id: String(j.id),
    conversationId: String(j.conversationId),
    senderId: String(j.senderId),
    body: String(j.body ?? ''),
    createdAt: new Date(String(j.createdAt)),
  };
}

export function parseGuidelines(j: Record<string, unknown>): TripGuidelines {
  const items = (raw: unknown) =>
    Array.isArray(raw)
      ? raw.map((e) => {
          const m = e as Record<string, unknown>;
          return { title: String(m.title ?? ''), body: String(m.body ?? '') };
        })
      : [];
  const hints = (raw: unknown) =>
    Array.isArray(raw)
      ? raw.map((e) => {
          const m = e as Record<string, unknown>;
          return { interest: String(m.interest ?? ''), suggestion: String(m.suggestion ?? '') };
        })
      : [];
  return {
    phase: String(j.phase ?? 'before'),
    role: String(j.role ?? 'co_rider'),
    heading: String(j.heading ?? 'Guidelines'),
    intro: String(j.intro ?? ''),
    common: items(j.common),
    expectations: items(j.expectations),
    conversationHints: hints(j.conversationHints),
    sharedInterests: Array.isArray(j.sharedInterests) ? j.sharedInterests.map(String) : [],
    partnerDisplayName: (j.partnerDisplayName as string) ?? null,
    viewerHasInterests: Boolean(j.viewerHasInterests),
    partnerHasInterests: Boolean(j.partnerHasInterests),
  };
}

export function parseDriveRoute(j: Record<string, unknown>): DriveRoute {
  const raw = (j.points as unknown[]) ?? [];
  const points = raw
    .filter((c): c is unknown[] => Array.isArray(c) && c.length >= 2)
    .map((c) => ({ latitude: Number(c[0]), longitude: Number(c[1]) }));
  const via = String(j.viaLabel ?? '').trim();
  return {
    points,
    distanceMeters: Number(j.distanceMeters ?? 0),
    durationSeconds: Number(j.durationSeconds ?? 0),
    trafficDelaySeconds: Number(j.trafficDelaySeconds ?? 0),
    usesLiveTraffic: j.usesLiveTraffic === true,
    index: Number(j.index ?? 0),
    viaLabel: via || null,
  };
}
