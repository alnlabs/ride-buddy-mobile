import {
  Booking,
  NeedInboxItem,
  Profile,
  Ride,
  RideOffer,
  RideRequest,
  RideSchedule,
  SavedPlace,
  TripGuidelines,
  Vehicle,
  parseBooking,
  parseGuidelines,
  parseInboxItem,
  parseNeed,
  parseOffer,
  parseProfile,
  parseRide,
  parseSavedPlace,
  parseSchedule,
  parseVehicle,
} from '@/src/models/types';
import { api } from '@/src/services/api';

const list = <T>(data: unknown, parse: (j: Record<string, unknown>) => T): T[] =>
  Array.isArray(data) ? data.map((e) => parse(e as Record<string, unknown>)) : [];

export const rideRepo = {
  vehicles: async (): Promise<Vehicle[]> => list((await api.get('/vehicles')).data, parseVehicle),
  createVehicle: async (body: Record<string, unknown>): Promise<Vehicle> =>
    parseVehicle((await api.post('/vehicles', body)).data),
  deleteVehicle: (id: string) => api.delete(`/vehicles/${id}`),
  setPrimary: (id: string) => api.post(`/vehicles/${id}/primary`),

  createRide: async (body: Record<string, unknown>): Promise<Ride> =>
    parseRide((await api.post('/rides', body)).data),
  myRides: async (): Promise<Ride[]> => list((await api.get('/rides/mine')).data, parseRide),
  openOwned: async (): Promise<Ride[]> => list((await api.get('/rides/open')).data, parseRide),
  searchRides: async (params: {
    originLat: number;
    originLng: number;
    destinationLat: number;
    destinationLng: number;
    radiusKm?: number;
    comfortOnly?: boolean;
    sameCommuteOnly?: boolean;
  }): Promise<Ride[]> => list((await api.get('/rides/search', { params })).data, parseRide),
  getRide: async (id: string): Promise<Ride> => parseRide((await api.get(`/rides/${id}`)).data),
  share: async (id: string): Promise<Record<string, unknown>> => (await api.get(`/rides/${id}/share`)).data,
  shareNeed: async (id: string): Promise<Record<string, unknown>> =>
    (await api.get(`/ride-requests/${id}/share`)).data,
  cancelRide: (id: string) => api.post(`/rides/${id}/cancel`),

  book: async (body: Record<string, unknown>): Promise<Booking> =>
    parseBooking((await api.post('/bookings', body)).data),
  myBookings: async (): Promise<Booking[]> => list((await api.get('/bookings/mine')).data, parseBooking),
  bookingsForRide: async (rideId: string): Promise<Booking[]> =>
    list((await api.get(`/bookings/ride/${rideId}`)).data, parseBooking),
  decideBooking: (id: string, accept: boolean) => api.post(`/bookings/${id}/decide`, { accept }),

  updateProfile: async (body: Record<string, unknown>): Promise<Profile> =>
    parseProfile((await api.put('/profile/me', body)).data),
  getProfile: async (): Promise<Profile> => parseProfile((await api.get('/profile/me')).data),
  savedPlaces: async (): Promise<SavedPlace[]> =>
    list((await api.get('/profile/me/saved-places')).data, parseSavedPlace),
  createSavedPlace: async (body: Record<string, unknown>): Promise<SavedPlace> =>
    parseSavedPlace((await api.post('/profile/me/saved-places', body)).data),
  updateSavedPlace: async (id: string, body: Record<string, unknown>): Promise<SavedPlace> =>
    parseSavedPlace((await api.put(`/profile/me/saved-places/${id}`, body)).data),
  deleteSavedPlace: (id: string) => api.delete(`/profile/me/saved-places/${id}`),
  setPrimarySavedPlace: async (id: string): Promise<SavedPlace> =>
    parseSavedPlace((await api.post(`/profile/me/saved-places/${id}/primary`)).data),
  updateInterests: async (tags: string[], topTags?: string[]): Promise<Profile> =>
    parseProfile((await api.put('/profile/me/interests', { tags, ...(topTags ? { topTags } : {}) })).data),
  requestOfficeEmail: async (email: string): Promise<Record<string, unknown>> =>
    (await api.post('/profile/me/office-email/request', { email })).data,
  verifyOfficeEmail: async (code: string): Promise<Profile> =>
    parseProfile((await api.post('/profile/me/office-email/verify', { code })).data),
  clearOfficeEmail: async (): Promise<Profile> =>
    parseProfile((await api.delete('/profile/me/office-email')).data),

  createNeed: async (body: Record<string, unknown>): Promise<RideRequest> =>
    parseNeed((await api.post('/ride-requests', body)).data),
  myNeeds: async (): Promise<RideRequest[]> => list((await api.get('/ride-requests/mine')).data, parseNeed),
  getNeed: async (id: string): Promise<RideRequest> => parseNeed((await api.get(`/ride-requests/${id}`)).data),
  cancelNeed: (id: string) => api.post(`/ride-requests/${id}/cancel`),
  needMatches: async (id: string): Promise<Ride[]> =>
    list((await api.get(`/ride-requests/${id}/matches`)).data, parseRide),
  needOffers: async (id: string): Promise<RideOffer[]> =>
    list((await api.get(`/ride-requests/${id}/offers`)).data, parseOffer),
  needsInbox: async (): Promise<NeedInboxItem[]> =>
    list((await api.get('/ride-requests/inbox')).data, parseInboxItem),
  rideMatchingNeeds: async (rideId: string): Promise<NeedInboxItem[]> =>
    list((await api.get(`/rides/${rideId}/matching-needs`)).data, parseInboxItem),
  offerSeat: async (requestId: string, rideId: string): Promise<RideOffer> =>
    parseOffer((await api.post('/ride-offers', { requestId, rideId })).data),
  decideOffer: (id: string, accept: boolean) => api.post(`/ride-offers/${id}/decide`, { accept }),

  tripGuidelinesForRide: async (rideId: string): Promise<TripGuidelines> =>
    parseGuidelines((await api.get(`/rides/${rideId}/trip-guidelines`)).data),
  tripGuidelinesForBooking: async (bookingId: string): Promise<TripGuidelines> =>
    parseGuidelines((await api.get(`/bookings/${bookingId}/trip-guidelines`)).data),

  createSchedule: async (body: Record<string, unknown>): Promise<RideSchedule> =>
    parseSchedule((await api.post('/ride-schedules', body)).data),
  mySchedules: async (): Promise<RideSchedule[]> =>
    list((await api.get('/ride-schedules/mine')).data, parseSchedule),
  pauseSchedule: async (id: string): Promise<RideSchedule> =>
    parseSchedule((await api.post(`/ride-schedules/${id}/pause`)).data),
  resumeSchedule: async (id: string): Promise<RideSchedule> =>
    parseSchedule((await api.post(`/ride-schedules/${id}/resume`)).data),
  cancelSchedule: async (id: string): Promise<RideSchedule> =>
    parseSchedule((await api.post(`/ride-schedules/${id}/cancel`)).data),
};
