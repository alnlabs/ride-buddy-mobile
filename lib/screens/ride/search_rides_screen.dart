import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ridebuddy/models/models.dart';
import 'package:ridebuddy/providers/location_provider.dart';
import 'package:ridebuddy/services/api_client.dart';
import 'package:ridebuddy/services/location_service.dart';
import 'package:ridebuddy/services/nominatim_service.dart';
import 'package:ridebuddy/services/ride_repository.dart';
import 'package:ridebuddy/theme/app_theme.dart';
import 'package:ridebuddy/widgets/common/empty_state.dart';
import 'package:ridebuddy/widgets/common/poster_identity.dart';
import 'package:ridebuddy/widgets/common/ui_kit.dart';
import 'package:ridebuddy/widgets/maps/place_search_field.dart';

class SearchRidesScreen extends ConsumerStatefulWidget {
  const SearchRidesScreen({super.key});

  @override
  ConsumerState<SearchRidesScreen> createState() => _SearchRidesScreenState();
}

class _SearchRidesScreenState extends ConsumerState<SearchRidesScreen> {
  final _fromKey = GlobalKey<PlaceSearchFieldState>();
  PlaceSuggestion? _from;
  PlaceSuggestion? _to;
  String? _userCity;
  double? _nearLat;
  double? _nearLng;
  bool _comfortOnly = false;
  bool _sameCommute = false;
  bool _loading = false;
  bool _searched = false;
  List<Ride> _results = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prefill());
  }

  Future<void> _prefill() async {
    try {
      final region = await ref.read(officeMapRegionProvider.future);
      if (!mounted) return;
      setState(() {
        _userCity = region.city;
        _nearLat = region.lat;
        _nearLng = region.lng;
        if (region.home != null && region.office != null) {
          final hour = DateTime.now().hour;
          final am = hour < 15;
          if (am) {
            _from = region.home;
            _to = region.office;
          } else {
            _from = region.office;
            _to = region.home;
          }
        }
      });
      _syncFromField();
      final to = _to;
      if (to != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // PlaceSearchField for To has no key — still ok for From bias/map.
        });
      }
    } catch (_) {}
  }

  void _syncFromField() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final from = _from;
      if (from != null) _fromKey.currentState?.applyPlace(from);
    });
  }

  Future<PlaceSuggestion?> _useMyLocation() async {
    final pos = await LocationService.currentPosition();
    if (pos == null) return null;
    final place = await ref.read(nominatimServiceProvider).reverseDetailed(pos.latitude, pos.longitude);
    if (place != null && mounted) {
      setState(() {
        _userCity = place.city;
        _nearLat = pos.latitude;
        _nearLng = pos.longitude;
      });
    }
    return place;
  }

  Future<void> _search() async {
    if (_from == null || _to == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick From and To from search suggestions')),
      );
      return;
    }
    if (!NominatimService.withinLocalTrip(_from!.lat, _from!.lng, _to!.lat, _to!.lng)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('To must be within ${kMaxLocalSearchKm.round()} km of From')),
      );
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _searched = true;
    });
    try {
      final list = await ref.read(rideRepositoryProvider).search(
            originLat: _from!.lat,
            originLng: _from!.lng,
            destinationLat: _to!.lat,
            destinationLng: _to!.lng,
            comfortOnly: _comfortOnly,
            sameCommuteOnly: _sameCommute,
          );
      setState(() => _results = list);
    } catch (e) {
      setState(() => _error = ref.read(apiClientProvider).messageFrom(e));
    } finally {
      setState(() => _loading = false);
    }
  }

  String _badge(String? type) {
    switch (type) {
      case 'same_route':
        return 'Same commute';
      case 'same_destination':
        return 'Same office';
      case 'same_origin':
        return 'Same neighborhood';
      case 'partial':
        return 'Partial match';
      default:
        return 'Nearby';
    }
  }

  String _short(String label) {
    if (label.length <= 36) return label;
    return '${label.substring(0, 34)}…';
  }

  @override
  Widget build(BuildContext context) {
    return SkyScaffold(
      appBar: AppBar(title: const Text('Find a ride')),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          SoftPanel(
            onTap: () => context.push('/ride/needs/new'),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.brandOrange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.hail_rounded, color: AppTheme.brandOrange),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Need a ride instead?', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        'Post your trip — hosts can offer; you can still book matches',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppTheme.inkMuted),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (_userCity != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(Icons.location_city_rounded, size: 18, color: AppTheme.brandBlue.withOpacity(0.8)),
                  const SizedBox(width: 6),
                  Text(
                    'Office city · $_userCity',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppTheme.brandBlue),
                  ),
                ],
              ),
            ),
          PlaceSearchField(
            key: _fromKey,
            label: 'From',
            initialText: _from?.label,
            searchCity: _userCity,
            nearLat: _nearLat,
            nearLng: _nearLng,
            onMyLocation: _useMyLocation,
            onSelected: (p) => setState(() => _from = p),
          ),
          const SizedBox(height: 10),
          PlaceSearchField(
            label: 'To',
            initialText: _to?.label,
            searchCity: _userCity,
            nearLat: _from?.lat ?? _nearLat,
            nearLng: _from?.lng ?? _nearLng,
            onSelected: (p) => setState(() => _to = p),
          ),
          const SizedBox(height: 8),
          SoftPanel(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Prefer comfort'),
                  subtitle: const Text('Comfort rides first — compact still shown'),
                  value: _comfortOnly,
                  onChanged: (v) => setState(() => _comfortOnly = v),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Same commute as me'),
                  value: _sameCommute,
                  onChanged: (v) => setState(() => _sameCommute = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          PrimaryButton(
            label: _loading ? 'Searching…' : 'Search rides',
            loading: _loading,
            icon: Icons.search_rounded,
            onPressed: _search,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            ErrorBanner(_error!),
          ],
          const SizedBox(height: 20),
          if (_searched && !_loading && _results.isEmpty)
            SoftPanel(
              child: EmptyState(
                title: 'No rides found',
                subtitle: 'Post a need so hosts can offer you a seat',
                icon: Icons.directions_car_outlined,
                actionLabel: 'Need a ride',
                onAction: () => context.push('/ride/needs/new'),
              ),
            ),
          ..._results.map((r) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SoftPanel(
                onTap: () => context.push(
                      '/ride/detail/${r.id}${_comfortOnly ? '?preferComfort=1' : ''}',
                    ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (r.poster != null) ...[
                      PosterIdentity(poster: r.poster!, roleBadge: 'Host', dense: true),
                      const SizedBox(height: 10),
                    ],
                    Text(
                      '${_short(r.originLabel)} → ${_short(r.destinationLabel)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${DateFormat.MMMd().add_jm().format(r.departAt)} · '
                      '${r.availableSeats} seats'
                      '${r.comfortRide ? ' · Comfort' : (_comfortOnly ? ' · Compact' : '')}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 10),
                    FareChip(pricePerSeat: r.pricePerSeat, compact: true),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.brandBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _badge(r.commuteMatchType),
                        style: const TextStyle(
                          color: AppTheme.brandBlue,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
