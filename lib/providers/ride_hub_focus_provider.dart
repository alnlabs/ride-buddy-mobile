import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ridebuddy/models/models.dart';

/// Set after posting a seat request so the Ride hub can show it and open matches on the map.
class RideHubFocus {
  const RideHubFocus({
    required this.needId,
    this.matches = const [],
    this.openMatchesMap = true,
  });

  final String needId;
  final List<Ride> matches;
  final bool openMatchesMap;
}

final rideHubFocusProvider = StateProvider<RideHubFocus?>((ref) => null);

/// Increment after ride/need/booking mutations so mounted list screens reload
/// when the user navigates back (IndexedStack / push stack keep State alive).
final rideDataRevisionProvider = StateProvider<int>((ref) => 0);

void bumpRideData(WidgetRef ref) {
  ref.read(rideDataRevisionProvider.notifier).update((v) => v + 1);
}
