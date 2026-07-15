import 'dart:convert';

class Profile {
  Profile({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    this.homeLat,
    this.homeLng,
    this.homeLabel,
    this.officeLat,
    this.officeLng,
    this.officeLabel,
    this.experienceBio,
    this.canOfferRides = false,
    this.profileStrength = 0,
    this.jobRole,
    this.company,
    this.contactEmail,
    this.officeEmail,
    this.officeEmailStatus = 'none',
    this.employeeVerified = false,
    this.interests = const [],
    this.topInterests = const [],
  });

  final String userId;
  final String displayName;
  final String? avatarUrl;
  final double? homeLat;
  final double? homeLng;
  final String? homeLabel;
  final double? officeLat;
  final double? officeLng;
  final String? officeLabel;
  final String? experienceBio;
  final bool canOfferRides;
  final int profileStrength;
  final String? jobRole;
  final String? company;
  final String? contactEmail;
  final String? officeEmail;
  final String officeEmailStatus;
  final bool employeeVerified;
  final List<String> interests;
  final List<String> topInterests;

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        userId: j['userId'] as String,
        displayName: j['displayName'] as String? ?? 'Rider',
        avatarUrl: j['avatarUrl'] as String?,
        homeLat: (j['homeLat'] as num?)?.toDouble(),
        homeLng: (j['homeLng'] as num?)?.toDouble(),
        homeLabel: j['homeLabel'] as String?,
        officeLat: (j['officeLat'] as num?)?.toDouble(),
        officeLng: (j['officeLng'] as num?)?.toDouble(),
        officeLabel: j['officeLabel'] as String?,
        experienceBio: j['experienceBio'] as String?,
        canOfferRides: j['canOfferRides'] as bool? ?? false,
        profileStrength: j['profileStrength'] as int? ?? 0,
        jobRole: j['jobRole'] as String?,
        company: j['company'] as String?,
        contactEmail: j['contactEmail'] as String?,
        officeEmail: j['officeEmail'] as String?,
        officeEmailStatus: j['officeEmailStatus'] as String? ?? 'none',
        employeeVerified: j['employeeVerified'] as bool? ?? false,
        interests: (j['interests'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        topInterests: (j['topInterests'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
            ((j['interests'] as List<dynamic>?)?.map((e) => e.toString()).take(5).toList() ?? []),
      );

  bool get hasPlaces => homeLat != null && officeLat != null;
  bool get hasWork => (jobRole?.trim().isNotEmpty ?? false) || (company?.trim().isNotEmpty ?? false);

  String? get workLine {
    final parts = <String>[
      if (jobRole != null && jobRole!.trim().isNotEmpty) jobRole!.trim(),
      if (company != null && company!.trim().isNotEmpty) company!.trim(),
    ];
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }

  String get emailSetupSubtitle {
    if (employeeVerified) return 'Verified employee · ${officeEmail ?? ''}';
    if (officeEmailStatus == 'pending') return 'Office email pending · enter code';
    if (contactEmail != null && contactEmail!.isNotEmpty) return 'Personal: $contactEmail';
    return 'Verify office email · personal Gmail optional';
  }
}

class PosterCard {
  PosterCard({
    required this.userId,
    required this.displayName,
    this.jobRole,
    this.company,
    this.topInterests = const [],
    this.employeeVerified = false,
  });

  final String userId;
  final String displayName;
  final String? jobRole;
  final String? company;
  final List<String> topInterests;
  final bool employeeVerified;

  factory PosterCard.fromJson(Map<String, dynamic>? j) {
    if (j == null) {
      return PosterCard(userId: '', displayName: 'Rider');
    }
    return PosterCard(
      userId: j['userId'] as String? ?? '',
      displayName: j['displayName'] as String? ?? 'Rider',
      jobRole: j['jobRole'] as String?,
      company: j['company'] as String?,
      topInterests: (j['topInterests'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      employeeVerified: j['employeeVerified'] as bool? ?? false,
    );
  }

  String? get workLine {
    final parts = <String>[
      if (jobRole != null && jobRole!.trim().isNotEmpty) jobRole!.trim(),
      if (company != null && company!.trim().isNotEmpty) company!.trim(),
    ];
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }
}

class Vehicle {
  Vehicle({
    required this.id,
    this.nickname,
    required this.makeModel,
    required this.plateMasked,
    this.plateNumber,
    required this.seats,
    this.color,
    required this.primary,
    required this.active,
  });

  final String id;
  final String? nickname;
  final String makeModel;
  final String plateMasked;
  final String? plateNumber;
  final int seats;
  final String? color;
  final bool primary;
  final bool active;

  factory Vehicle.fromJson(Map<String, dynamic> j) => Vehicle(
        id: j['id'] as String,
        nickname: j['nickname'] as String?,
        makeModel: j['makeModel'] as String,
        plateMasked: j['plateMasked'] as String? ?? '****',
        plateNumber: j['plateNumber'] as String?,
        seats: j['seats'] as int,
        color: j['color'] as String?,
        primary: j['primary'] as bool? ?? false,
        active: j['active'] as bool? ?? true,
      );

  String get displayName => nickname?.isNotEmpty == true ? nickname! : makeModel;
}

class Ride {
  Ride({
    required this.id,
    required this.ownerId,
    required this.vehicleId,
    required this.status,
    required this.comfortRide,
    required this.originLat,
    required this.originLng,
    required this.originLabel,
    required this.destinationLat,
    required this.destinationLng,
    required this.destinationLabel,
    required this.departAt,
    required this.availableSeats,
    required this.pricePerSeat,
    this.commuteMatchType,
    this.detourKm,
    this.routeGeometry,
    this.routeDistanceM,
    this.routeDurationS,
    this.poster,
  });

  final String id;
  final String ownerId;
  final String vehicleId;
  final String status;
  final bool comfortRide;
  final double originLat;
  final double originLng;
  final String originLabel;
  final double destinationLat;
  final double destinationLng;
  final String destinationLabel;
  final DateTime departAt;
  final int availableSeats;
  final double pricePerSeat;
  final String? commuteMatchType;
  final double? detourKm;
  final List<List<double>>? routeGeometry;
  final double? routeDistanceM;
  final double? routeDurationS;
  final PosterCard? poster;

  factory Ride.fromJson(Map<String, dynamic> j) {
    List<List<double>>? geometry;
    final raw = j['routeGeometry'];
    List? coords;
    if (raw is List) {
      coords = raw;
    } else if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) coords = decoded;
      } catch (_) {}
    }
    if (coords != null) {
      geometry = coords
          .whereType<List>()
          .where((e) => e.length >= 2)
          .map((e) => <double>[(e[0] as num).toDouble(), (e[1] as num).toDouble()])
          .toList();
      if (geometry.length < 2) geometry = null;
    }
    return Ride(
      id: j['id'] as String,
      ownerId: j['ownerId'] as String,
      vehicleId: j['vehicleId'] as String,
      status: j['status'] as String,
      comfortRide: j['comfortRide'] as bool? ?? false,
      originLat: (j['originLat'] as num).toDouble(),
      originLng: (j['originLng'] as num).toDouble(),
      originLabel: j['originLabel'] as String,
      destinationLat: (j['destinationLat'] as num).toDouble(),
      destinationLng: (j['destinationLng'] as num).toDouble(),
      destinationLabel: j['destinationLabel'] as String,
      departAt: DateTime.parse(j['departAt'] as String).toLocal(),
      availableSeats: j['availableSeats'] as int,
      pricePerSeat: (j['pricePerSeat'] as num).toDouble(),
      commuteMatchType: j['commuteMatchType'] as String?,
      detourKm: (j['detourKm'] as num?)?.toDouble(),
      routeGeometry: geometry,
      routeDistanceM: (j['routeDistanceM'] as num?)?.toDouble(),
      routeDurationS: (j['routeDurationS'] as num?)?.toDouble(),
      poster: j['poster'] is Map<String, dynamic>
          ? PosterCard.fromJson(j['poster'] as Map<String, dynamic>)
          : null,
    );
  }
}

class Booking {
  Booking({
    required this.id,
    required this.rideId,
    required this.status,
    required this.seatsRequested,
    required this.amount,
    required this.paymentMethod,
    this.pickupLabel,
    this.dropLabel,
    this.rideOriginLabel,
    this.rideDestinationLabel,
    this.departAt,
  });

  final String id;
  final String rideId;
  final String status;
  final int seatsRequested;
  final double amount;
  final String paymentMethod;
  final String? pickupLabel;
  final String? dropLabel;
  final String? rideOriginLabel;
  final String? rideDestinationLabel;
  final DateTime? departAt;

  factory Booking.fromJson(Map<String, dynamic> j) => Booking(
        id: j['id'] as String,
        rideId: j['rideId'] as String,
        status: j['status'] as String,
        seatsRequested: j['seatsRequested'] as int,
        amount: (j['amount'] as num).toDouble(),
        paymentMethod: j['paymentMethod'] as String? ?? 'cash',
        pickupLabel: j['pickupLabel'] as String?,
        dropLabel: j['dropLabel'] as String?,
        rideOriginLabel: j['rideOriginLabel'] as String?,
        rideDestinationLabel: j['rideDestinationLabel'] as String?,
        departAt: j['departAt'] != null ? DateTime.parse(j['departAt'] as String).toLocal() : null,
      );
}

class RideRequest {
  RideRequest({
    required this.id,
    required this.requesterId,
    required this.originLat,
    required this.originLng,
    required this.originLabel,
    required this.destinationLat,
    required this.destinationLng,
    required this.destinationLabel,
    required this.departAt,
    required this.seatsNeeded,
    required this.comfortPreferred,
    required this.status,
    this.matchedRideId,
    this.matchedBookingId,
    this.poster,
  });

  final String id;
  final String requesterId;
  final double originLat;
  final double originLng;
  final String originLabel;
  final double destinationLat;
  final double destinationLng;
  final String destinationLabel;
  final DateTime departAt;
  final int seatsNeeded;
  final bool comfortPreferred;
  final String status;
  final String? matchedRideId;
  final String? matchedBookingId;
  final PosterCard? poster;

  factory RideRequest.fromJson(Map<String, dynamic> j) => RideRequest(
        id: j['id'] as String,
        requesterId: j['requesterId'] as String,
        originLat: (j['originLat'] as num).toDouble(),
        originLng: (j['originLng'] as num).toDouble(),
        originLabel: j['originLabel'] as String,
        destinationLat: (j['destinationLat'] as num).toDouble(),
        destinationLng: (j['destinationLng'] as num).toDouble(),
        destinationLabel: j['destinationLabel'] as String,
        departAt: DateTime.parse(j['departAt'] as String).toLocal(),
        seatsNeeded: j['seatsNeeded'] as int? ?? 1,
        comfortPreferred: j['comfortPreferred'] as bool? ?? false,
        status: j['status'] as String,
        matchedRideId: j['matchedRideId'] as String?,
        matchedBookingId: j['matchedBookingId'] as String?,
        poster: j['poster'] is Map<String, dynamic>
            ? PosterCard.fromJson(j['poster'] as Map<String, dynamic>)
            : null,
      );
}

class RideOffer {
  RideOffer({
    required this.id,
    required this.requestId,
    required this.rideId,
    required this.ownerId,
    required this.status,
    this.request,
    this.ride,
  });

  final String id;
  final String requestId;
  final String rideId;
  final String ownerId;
  final String status;
  final RideRequest? request;
  final Ride? ride;

  factory RideOffer.fromJson(Map<String, dynamic> j) => RideOffer(
        id: j['id'] as String,
        requestId: j['requestId'] as String,
        rideId: j['rideId'] as String,
        ownerId: j['ownerId'] as String,
        status: j['status'] as String,
        request: j['request'] is Map<String, dynamic>
            ? RideRequest.fromJson(j['request'] as Map<String, dynamic>)
            : null,
        ride: j['ride'] is Map<String, dynamic> ? Ride.fromJson(j['ride'] as Map<String, dynamic>) : null,
      );
}

class NeedInboxItem {
  NeedInboxItem({
    required this.request,
    required this.suggestedRideId,
    required this.detourKm,
    required this.alreadyOffered,
  });

  final RideRequest request;
  final String suggestedRideId;
  final double detourKm;
  final bool alreadyOffered;

  factory NeedInboxItem.fromJson(Map<String, dynamic> j) => NeedInboxItem(
        request: RideRequest.fromJson(j['request'] as Map<String, dynamic>),
        suggestedRideId: j['suggestedRideId'] as String,
        detourKm: (j['detourKm'] as num).toDouble(),
        alreadyOffered: j['alreadyOffered'] as bool? ?? false,
      );
}
