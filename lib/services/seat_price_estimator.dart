/// How many passengers sit in the back row — drives capacity and ₹/seat.
enum BackSeatMode {
  /// Roomier: max 2 in the back → higher price per seat.
  spacious2,

  /// Standard: up to 3 in the back → lower price per seat (cost shared more).
  standard3,
}

extension BackSeatModeX on BackSeatMode {
  int get backSeats => this == BackSeatMode.spacious2 ? 2 : 3;

  bool get isComfort => this == BackSeatMode.spacious2;

  String get title => this == BackSeatMode.spacious2 ? '2 in the back' : '3 in the back';

  String get subtitle => this == BackSeatMode.spacious2
      ? 'Spacious / comfort · higher ₹ per seat'
      : 'Standard · lower ₹ per seat (shared more)';
}

/// Suggests a fair cash price per seat for Indian office carpools.
///
/// Running cost is shared across offered seats, so **3 back seats → cheaper
/// per seat** than **2 spacious back seats** (comfort premium + fewer sharers).
class SeatPriceEstimate {
  SeatPriceEstimate({
    required this.suggestedPerSeat,
    required this.distanceKm,
    required this.durationMinutes,
    required this.seats,
    required this.totalRunningCost,
    required this.peak,
    required this.backSeatMode,
    required this.summary,
  });

  final int suggestedPerSeat;
  final double distanceKm;
  final int durationMinutes;
  final int seats;
  final double totalRunningCost;
  final bool peak;
  final BackSeatMode backSeatMode;
  final String summary;

  bool get comfort => backSeatMode.isComfort;
}

class SeatPriceEstimator {
  /// Shareable running cost per km (fuel + light wear).
  static const double rupeesPerKm = 7.5;

  /// Fixed friction / time cost for the trip (split across seats).
  static const double baseFee = 25;

  static const int minPerSeat = 20;
  static const int maxPerSeat = 250;

  /// Max back-row passengers this vehicle can sell for [mode].
  static int maxBackSeatsFor(int vehicleTotalSeats, BackSeatMode mode) {
    final passengerCap = (vehicleTotalSeats - 1).clamp(1, 8);
    return mode.backSeats.clamp(1, passengerCap);
  }

  /// Whether a 5-seater-class car can offer 3 across the rear.
  static bool canOfferThreeBack(int vehicleTotalSeats) {
    return vehicleTotalSeats - 1 >= 3;
  }

  static SeatPriceEstimate estimate({
    required double distanceMeters,
    required double durationSeconds,
    required int seats,
    required DateTime departAt,
    required BackSeatMode backSeatMode,
  }) {
    final seatCount = seats.clamp(1, 8);
    final km = (distanceMeters / 1000).clamp(0.5, 100.0);
    final mins = (durationSeconds / 60).round().clamp(1, 240);
    final peak = _isPeak(departAt);

    final expectedMins = (km * 2.2).round().clamp(1, 240);
    final congestionExtra = mins > expectedMins ? (mins - expectedMins) * 0.6 : 0.0;

    var total = baseFee + (km * rupeesPerKm) + congestionExtra;
    if (peak) total *= 1.12;

    if (backSeatMode == BackSeatMode.spacious2) {
      // Roomier cabin: hosts recover more per passenger.
      total = total * 1.18 + 35;
    } else {
      // Three-abreast: slightly softer total; mainly cheaper via /3 split.
      total *= 0.97;
    }

    final raw = total / seatCount;
    final suggested = _roundToFive(raw).clamp(minPerSeat, maxPerSeat);

    final parts = <String>[
      '${km >= 10 ? km.toStringAsFixed(0) : km.toStringAsFixed(1)} km',
      '${backSeatMode.backSeats} back · $seatCount offered',
      if (peak) 'peak hour',
      if (backSeatMode.isComfort) 'spacious',
    ];

    return SeatPriceEstimate(
      suggestedPerSeat: suggested,
      distanceKm: km,
      durationMinutes: mins,
      seats: seatCount,
      totalRunningCost: total,
      peak: peak,
      backSeatMode: backSeatMode,
      summary: 'Suggested ₹$suggested · ${parts.join(' · ')}',
    );
  }

  static bool _isPeak(DateTime depart) {
    final h = depart.hour;
    return (h >= 7 && h < 11) || (h >= 17 && h < 21);
  }

  static int _roundToFive(double value) {
    if (value <= 0) return minPerSeat;
    return (value / 5).round() * 5;
  }
}
