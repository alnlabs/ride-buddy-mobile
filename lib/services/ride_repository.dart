import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ridebuddy/models/models.dart';
import 'package:ridebuddy/models/trip_guidelines.dart';
import 'package:ridebuddy/services/api_client.dart';

final rideRepositoryProvider = Provider((ref) => RideRepository(ref));

class RideRepository {
  RideRepository(this._ref);
  final Ref _ref;

  ApiClient get _api => _ref.read(apiClientProvider);

  Future<List<Vehicle>> vehicles() async {
    final res = await _api.dio.get('/vehicles');
    return (res.data as List).map((e) => Vehicle.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Vehicle> createVehicle(Map<String, dynamic> body) async {
    final res = await _api.dio.post('/vehicles', data: body);
    return Vehicle.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteVehicle(String id) async {
    await _api.dio.delete('/vehicles/$id');
  }

  Future<void> setPrimary(String id) async {
    await _api.dio.post('/vehicles/$id/primary');
  }

  Future<Ride> createRide(Map<String, dynamic> body) async {
    final res = await _api.dio.post('/rides', data: body);
    return Ride.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<Ride>> myRides() async {
    final res = await _api.dio.get('/rides/mine');
    return (res.data as List).map((e) => Ride.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Ride>> openOwned() async {
    final res = await _api.dio.get('/rides/open');
    return (res.data as List).map((e) => Ride.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Ride>> search({
    required double originLat,
    required double originLng,
    required double destinationLat,
    required double destinationLng,
    bool comfortOnly = false,
    bool sameCommuteOnly = false,
  }) async {
    final res = await _api.dio.get('/rides/search', queryParameters: {
      'originLat': originLat,
      'originLng': originLng,
      'destinationLat': destinationLat,
      'destinationLng': destinationLng,
      'comfortOnly': comfortOnly,
      'sameCommuteOnly': sameCommuteOnly,
    });
    return (res.data as List).map((e) => Ride.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Ride> getRide(String id) async {
    final res = await _api.dio.get('/rides/$id');
    return Ride.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> share(String id) async {
    final res = await _api.dio.get('/rides/$id/share');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> shareNeed(String id) async {
    final res = await _api.dio.get('/ride-requests/$id/share');
    return res.data as Map<String, dynamic>;
  }

  Future<void> cancelRide(String id) async {
    await _api.dio.post('/rides/$id/cancel');
  }

  Future<Booking> book(Map<String, dynamic> body) async {
    final res = await _api.dio.post('/bookings', data: body);
    return Booking.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<Booking>> myBookings() async {
    final res = await _api.dio.get('/bookings/mine');
    return (res.data as List).map((e) => Booking.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Booking>> bookingsForRide(String rideId) async {
    final res = await _api.dio.get('/bookings/ride/$rideId');
    return (res.data as List).map((e) => Booking.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> decideBooking(String id, bool accept) async {
    await _api.dio.post('/bookings/$id/decide', data: {'accept': accept});
  }

  Future<Profile> updateProfile(Map<String, dynamic> body) async {
    final res = await _api.dio.put('/profile/me', data: body);
    return Profile.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Profile> updatePlaces(Map<String, dynamic> body) async {
    final res = await _api.dio.put('/profile/me/places', data: body);
    return Profile.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<SavedPlace>> savedPlaces() async {
    final res = await _api.dio.get('/profile/me/saved-places');
    return (res.data as List).map((e) => SavedPlace.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<SavedPlace> createSavedPlace(Map<String, dynamic> body) async {
    final res = await _api.dio.post('/profile/me/saved-places', data: body);
    return SavedPlace.fromJson(res.data as Map<String, dynamic>);
  }

  Future<SavedPlace> updateSavedPlace(String id, Map<String, dynamic> body) async {
    final res = await _api.dio.put('/profile/me/saved-places/$id', data: body);
    return SavedPlace.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteSavedPlace(String id) async {
    await _api.dio.delete('/profile/me/saved-places/$id');
  }

  Future<SavedPlace> setPrimarySavedPlace(String id) async {
    final res = await _api.dio.post('/profile/me/saved-places/$id/primary');
    return SavedPlace.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Profile> updateInterests(List<String> tags, {List<String>? topTags}) async {
    final res = await _api.dio.put('/profile/me/interests', data: {
      'tags': tags,
      if (topTags != null) 'topTags': topTags,
    });
    return Profile.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> requestOfficeEmail(String email) async {
    final res = await _api.dio.post('/profile/me/office-email/request', data: {'email': email});
    return res.data as Map<String, dynamic>;
  }

  Future<Profile> verifyOfficeEmail(String code) async {
    final res = await _api.dio.post('/profile/me/office-email/verify', data: {'code': code});
    return Profile.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Profile> clearOfficeEmail() async {
    final res = await _api.dio.delete('/profile/me/office-email');
    return Profile.fromJson(res.data as Map<String, dynamic>);
  }

  Future<RideRequest> createNeed(Map<String, dynamic> body) async {
    final res = await _api.dio.post('/ride-requests', data: body);
    return RideRequest.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<RideRequest>> myNeeds() async {
    final res = await _api.dio.get('/ride-requests/mine');
    return (res.data as List).map((e) => RideRequest.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<RideRequest> getNeed(String id) async {
    final res = await _api.dio.get('/ride-requests/$id');
    return RideRequest.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> cancelNeed(String id) async {
    await _api.dio.post('/ride-requests/$id/cancel');
  }

  Future<List<Ride>> needMatches(String id) async {
    final res = await _api.dio.get('/ride-requests/$id/matches');
    return (res.data as List).map((e) => Ride.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<RideOffer>> needOffers(String id) async {
    final res = await _api.dio.get('/ride-requests/$id/offers');
    return (res.data as List).map((e) => RideOffer.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<NeedInboxItem>> needsInbox() async {
    final res = await _api.dio.get('/ride-requests/inbox');
    return (res.data as List).map((e) => NeedInboxItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<NeedInboxItem>> rideMatchingNeeds(String rideId) async {
    final res = await _api.dio.get('/rides/$rideId/matching-needs');
    return (res.data as List).map((e) => NeedInboxItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<RideOffer> offerSeat({required String requestId, required String rideId}) async {
    final res = await _api.dio.post('/ride-offers', data: {
      'requestId': requestId,
      'rideId': rideId,
    });
    return RideOffer.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<RideOffer>> myOffers() async {
    final res = await _api.dio.get('/ride-offers/mine');
    return (res.data as List).map((e) => RideOffer.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> decideOffer(String id, bool accept) async {
    await _api.dio.post('/ride-offers/$id/decide', data: {'accept': accept});
  }

  Future<TripGuidelines> tripGuidelinesForRide(String rideId) async {
    final res = await _api.dio.get('/rides/$rideId/trip-guidelines');
    return TripGuidelines.fromJson(res.data as Map<String, dynamic>);
  }

  Future<TripGuidelines> tripGuidelinesForBooking(String bookingId) async {
    final res = await _api.dio.get('/bookings/$bookingId/trip-guidelines');
    return TripGuidelines.fromJson(res.data as Map<String, dynamic>);
  }

  Future<RideSchedule> createSchedule(Map<String, dynamic> body) async {
    final res = await _api.dio.post('/ride-schedules', data: body);
    return RideSchedule.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<RideSchedule>> mySchedules() async {
    final res = await _api.dio.get('/ride-schedules/mine');
    return (res.data as List).map((e) => RideSchedule.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<RideSchedule> pauseSchedule(String id) async {
    final res = await _api.dio.post('/ride-schedules/$id/pause');
    return RideSchedule.fromJson(res.data as Map<String, dynamic>);
  }

  Future<RideSchedule> resumeSchedule(String id) async {
    final res = await _api.dio.post('/ride-schedules/$id/resume');
    return RideSchedule.fromJson(res.data as Map<String, dynamic>);
  }

  Future<RideSchedule> cancelSchedule(String id) async {
    final res = await _api.dio.post('/ride-schedules/$id/cancel');
    return RideSchedule.fromJson(res.data as Map<String, dynamic>);
  }
}
