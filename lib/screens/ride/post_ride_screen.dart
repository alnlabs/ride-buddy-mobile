import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:ridebuddy/models/models.dart';
import 'package:ridebuddy/providers/location_provider.dart';
import 'package:ridebuddy/screens/vehicle/vehicles_screen.dart';
import 'package:ridebuddy/services/api_client.dart';
import 'package:ridebuddy/services/location_service.dart';
import 'package:ridebuddy/services/nominatim_service.dart';
import 'package:ridebuddy/services/ride_repository.dart';
import 'package:ridebuddy/services/routing_service.dart';
import 'package:ridebuddy/services/seat_price_estimator.dart';
import 'package:ridebuddy/theme/app_theme.dart';
import 'package:ridebuddy/widgets/common/ui_kit.dart';
import 'package:ridebuddy/widgets/maps/osm_map_view.dart';
import 'package:ridebuddy/widgets/maps/place_search_field.dart';

class PostRideScreen extends ConsumerStatefulWidget {
  const PostRideScreen({super.key});

  @override
  ConsumerState<PostRideScreen> createState() => _PostRideScreenState();
}

class _PostRideScreenState extends ConsumerState<PostRideScreen> {
  final _fromKey = GlobalKey<PlaceSearchFieldState>();
  final _toKey = GlobalKey<PlaceSearchFieldState>();
  PlaceSuggestion? _from;
  PlaceSuggestion? _to;
  String? _userCity;
  double? _nearLat;
  double? _nearLng;
  bool _locating = false;
  Vehicle? _vehicle;
  BackSeatMode _backSeatMode = BackSeatMode.standard3;
  DateTime _depart = DateTime.now().add(const Duration(hours: 1));
  final _price = TextEditingController();
  final _seats = TextEditingController(text: '3');
  bool _saving = false;
  String? _error;
  bool _priceManual = false;
  SeatPriceEstimate? _priceEstimate;

  List<DriveRoute> _routes = [];
  int _selectedRoute = 0;
  bool _routing = false;
  String? _routeError;
  int _routeSeq = 0;
  int _step = 0;

  static const _stepTitles = ['Route', 'Vehicle', 'When & price'];

  @override
  void initState() {
    super.initState();
    _seats.addListener(_onSeatsChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDefaults());
  }

  void _onSeatsChanged() {
    if (!mounted) return;
    _recalculatePrice();
  }

  Future<void> _loadDefaults() async {
    try {
      final region = await ref.read(officeMapRegionProvider.future);
      if (!mounted) return;
      setState(() {
        _userCity = region.city;
        _nearLat = region.lat;
        _nearLng = region.lng;
        if (region.home != null) _from = region.home;
        if (region.office != null) _to = region.office;
      });
      _syncFromField();
      final to = region.office;
      if (to != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _toKey.currentState?.applyPlace(to);
        });
      }
      await _loadRoutes();
    } catch (_) {}

    try {
      final vehicles = await ref.read(rideRepositoryProvider).vehicles();
      if (!mounted) return;
      if (vehicles.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add a vehicle before posting a ride')),
        );
        context.push('/profile/vehicles');
        return;
      }
      setState(() => _vehicle = vehicles.firstWhere((v) => v.primary, orElse: () => vehicles.first));
      _syncSeatsDefault();
      ref.invalidate(vehiclesProvider);
    } catch (e) {
      if (mounted) setState(() => _error = ref.read(apiClientProvider).messageFrom(e));
    }
  }

  bool get _comfort => _backSeatMode.isComfort;

  int _maxOfferSeats() {
    final v = _vehicle;
    if (v == null) return 3;
    return SeatPriceEstimator.maxBackSeatsFor(v.seats, _backSeatMode);
  }

  void _syncSeatsDefault({bool forceToMax = true}) {
    final v = _vehicle;
    if (v == null) return;
    if (!SeatPriceEstimator.canOfferThreeBack(v.seats) && _backSeatMode == BackSeatMode.standard3) {
      _backSeatMode = BackSeatMode.spacious2;
    }
    final maxOffer = _maxOfferSeats();
    final current = int.tryParse(_seats.text);
    if (forceToMax || current == null || current > maxOffer || current < 1) {
      _seats.text = '$maxOffer';
    }
    _recalculatePrice();
  }

  void _recalculatePrice({bool force = false}) {
    final route = _routes.isNotEmpty && _selectedRoute < _routes.length ? _routes[_selectedRoute] : null;
    if (route == null) {
      setState(() => _priceEstimate = null);
      return;
    }
    final seats = int.tryParse(_seats.text) ?? _maxOfferSeats();
    final estimate = SeatPriceEstimator.estimate(
      distanceMeters: route.distanceMeters,
      durationSeconds: route.durationSeconds,
      seats: seats,
      departAt: _depart,
      backSeatMode: _backSeatMode,
    );
    setState(() {
      _priceEstimate = estimate;
      final empty = _price.text.trim().isEmpty;
      // Guide can pre-fill; once the host types, their number is final.
      if (force || !_priceManual || empty) {
        _price.text = '${estimate.suggestedPerSeat}';
      }
      if (force || empty) {
        _priceManual = false;
      }
    });
  }

  Future<void> _loadRoutes() async {
    final from = _from;
    final to = _to;
    if (from == null || to == null) {
      setState(() {
        _routes = [];
        _selectedRoute = 0;
        _routeError = null;
        _priceEstimate = null;
      });
      return;
    }
    final seq = ++_routeSeq;
    setState(() {
      _routing = true;
      _routeError = null;
    });
    try {
      final list = await ref.read(routingServiceProvider).routes(
            LatLng(from.lat, from.lng),
            LatLng(to.lat, to.lng),
          );
      if (!mounted || seq != _routeSeq) return;
      setState(() {
        _routes = list;
        _selectedRoute = 0;
        _routeError = list.isEmpty ? 'Could not find a driving route — check places or try again' : null;
      });
      _recalculatePrice();
    } catch (_) {
      if (!mounted || seq != _routeSeq) return;
      setState(() {
        _routes = [];
        _routeError = 'Route lookup failed — check internet';
        _priceEstimate = null;
      });
    } finally {
      if (mounted && seq == _routeSeq) setState(() => _routing = false);
    }
  }

  void _onFromSelected(PlaceSuggestion p) {
    setState(() {
      _from = p;
      if (_to != null &&
          !NominatimService.withinLocalTrip(p.lat, p.lng, _to!.lat, _to!.lng)) {
        _to = null;
        _routes = [];
        _routeError = null;
        _toKey.currentState?.clear();
      }
    });
    _loadRoutes();
  }

  void _onToSelected(PlaceSuggestion p) {
    if (_from != null &&
        !NominatimService.withinLocalTrip(_from!.lat, _from!.lng, p.lat, p.lng)) {
      setState(() {
        _error = 'Pick a destination within ${kMaxLocalSearchKm.round()} km of From';
        _to = null;
      });
      return;
    }
    setState(() {
      _to = p;
      _error = null;
    });
    _loadRoutes();
  }

  void _swapEnds() {
    final from = _from;
    final to = _to;
    setState(() {
      _from = to;
      _to = from;
      _error = null;
    });
    if (to != null) _fromKey.currentState?.applyPlace(to);
    if (from != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _toKey.currentState?.applyPlace(from);
      });
    } else {
      _toKey.currentState?.clear();
    }
    _loadRoutes();
  }

  @override
  void dispose() {
    _seats.removeListener(_onSeatsChanged);
    _price.dispose();
    _seats.dispose();
    super.dispose();
  }

  Future<void> _pickDepart() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      initialDate: _depart,
    );
    if (date == null) return;
    if (!mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_depart));
    if (time == null) return;
    setState(() {
      _depart = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
    _recalculatePrice();
  }

  Future<void> _publish() async {
    var from = _from ?? await _fromKey.currentState?.resolveSelection();
    var to = _to ?? await _toKey.currentState?.resolveSelection();
    if (from != null) _from = from;
    if (to != null) _to = to;

    if (_from == null || _to == null || _vehicle == null) {
      setState(() => _error = 'Pick From, To, and a vehicle before publishing');
      return;
    }
    if (!NominatimService.withinLocalTrip(_from!.lat, _from!.lng, _to!.lat, _to!.lng)) {
      setState(() => _error = 'Destination must be within ${kMaxLocalSearchKm.round()} km of the start location');
      return;
    }
    if (_comfort && _vehicle!.seats < 4) {
      setState(() => _error = 'Spacious (2 back seats) needs a 4+ seat vehicle');
      return;
    }
    final seats = int.tryParse(_seats.text) ?? 0;
    final maxOffer = _maxOfferSeats();
    if (seats < 1 || seats > maxOffer) {
      setState(() => _error = 'Offer between 1 and $maxOffer seat(s) for ${_backSeatMode.title}');
      return;
    }
    final price = double.tryParse(_price.text) ?? 0;
    if (price < SeatPriceEstimator.minPerSeat) {
      setState(() => _error = 'Price per seat should be at least ₹${SeatPriceEstimator.minPerSeat}');
      return;
    }
    if (_routes.isEmpty) {
      await _loadRoutes();
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final selected = _routes.isNotEmpty && _selectedRoute < _routes.length ? _routes[_selectedRoute] : null;
      final ride = await ref.read(rideRepositoryProvider).createRide({
        'vehicleId': _vehicle!.id,
        'rideType': 'scheduled',
        'comfortRide': _comfort,
        'originLat': _from!.lat,
        'originLng': _from!.lng,
        'originLabel': _from!.label,
        'destinationLat': _to!.lat,
        'destinationLng': _to!.lng,
        'destinationLabel': _to!.label,
        'departAt': _depart.toUtc().toIso8601String(),
        'availableSeats': seats,
        'pricePerSeat': double.tryParse(_price.text) ?? 0,
        'recurring': false,
        if (selected != null) 'routeGeometry': selected.toJsonCoords(),
        if (selected != null) 'routeDistanceM': selected.distanceMeters,
        if (selected != null) 'routeDurationS': selected.durationSeconds,
      });
      if (mounted) context.push('/ride/detail/${ride.id}');
    } catch (e) {
      setState(() => _error = ref.read(apiClientProvider).messageFrom(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _syncFromField() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final from = _from;
      if (from != null) _fromKey.currentState?.applyPlace(from);
    });
  }

  Future<PlaceSuggestion?> _useMyLocation() async {
    setState(() => _locating = true);
    try {
      final pos = await LocationService.currentPosition();
      if (pos == null) return null;
      final place = await ref.read(nominatimServiceProvider).reverseDetailed(pos.latitude, pos.longitude);
      if (place != null && mounted) {
        setState(() {
          _userCity = place.city;
          _nearLat = pos.latitude;
          _nearLng = pos.longitude;
          _from = place;
        });
        await _loadRoutes();
      }
      return place;
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  bool get _vehicleReady => _vehicle != null;

  Future<bool> _validateRouteStep() async {
    var from = _from ?? await _fromKey.currentState?.resolveSelection();
    var to = _to ?? await _toKey.currentState?.resolveSelection();
    if (from != null) _from = from;
    if (to != null) _to = to;
    if (_from == null || _to == null) {
      setState(() => _error = 'Pick From and To to continue');
      return false;
    }
    if (!NominatimService.withinLocalTrip(_from!.lat, _from!.lng, _to!.lat, _to!.lng)) {
      setState(() => _error = 'To must be within ${kMaxLocalSearchKm.round()} km of From');
      return false;
    }
    if (_routes.isEmpty && !_routing) {
      await _loadRoutes();
    }
    if (_routes.isEmpty) {
      setState(() => _error = _routeError ?? 'Wait for a driving route, then continue');
      return false;
    }
    setState(() => _error = null);
    return true;
  }

  bool _validateVehicleStep() {
    if (_vehicle == null) {
      setState(() => _error = 'Pick a vehicle to continue');
      return false;
    }
    setState(() => _error = null);
    return true;
  }

  Future<void> _goNext() async {
    if (_step == 0) {
      if (!await _validateRouteStep()) return;
      setState(() => _step = 1);
      return;
    }
    if (_step == 1) {
      if (!_validateVehicleStep()) return;
      setState(() => _step = 2);
      _recalculatePrice();
      return;
    }
    await _publish();
  }

  void _goBack() {
    if (_step > 0) {
      setState(() {
        _step -= 1;
        _error = null;
      });
    } else {
      context.pop();
    }
  }

  String _short(String label) {
    if (label.length <= 36) return label;
    return '${label.substring(0, 34)}…';
  }

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final mapCenter = LatLng(
      _nearLat ?? _to?.lat ?? _from?.lat ?? 17.385,
      _nearLng ?? _to?.lng ?? _from?.lng ?? 78.4867,
    );
    final selected = _routes.isNotEmpty && _selectedRoute < _routes.length ? _routes[_selectedRoute] : null;
    final maxSeats = _maxOfferSeats();
    final priceVal = double.tryParse(_price.text) ?? 0;

    return PopScope(
      canPop: _step == 0,
      onPopInvoked: (didPop) {
        if (!didPop) _goBack();
      },
      child: SkyScaffold(
        appBar: AppBar(
          title: Text(_stepTitles[_step]),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _goBack,
          ),
          actions: [
            if (_userCity != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Text(
                    _userCity!,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.brandBlue),
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: _WizardBar(
          step: _step,
          stepCount: _stepTitles.length,
          saving: _saving,
          primaryLabel: _step == 2 ? 'Publish' : 'Continue',
          primaryEnabled: _step == 0
              ? (_from != null && _to != null && !_routing)
              : _step == 1
                  ? _vehicleReady
                  : true,
          subtitle: _step == 2
              ? (priceVal <= 0
                  ? 'Set your price'
                  : '₹${priceVal.toStringAsFixed(0)} / seat · ${_seats.text} seats'
                      '${selected != null ? ' · ${selected.durationLabel}' : ''}')
              : _step == 0 && selected != null
                  ? '${selected.durationLabel} · ${selected.distanceLabel}'
                  : _step == 1 && _vehicle != null
                      ? _vehicle!.displayName
                      : 'Step ${_step + 1} of ${_stepTitles.length}',
          onBack: _step > 0 ? _goBack : null,
          onPrimary: _goNext,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: _StepProgress(step: _step, labels: _stepTitles),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: KeyedSubtree(
                  key: ValueKey(_step),
                  child: _step == 0
                      ? _buildRouteStepBody(mapCenter, selected)
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          children: [
                            if (_step == 1) ..._buildVehicleStep(vehiclesAsync),
                            if (_step == 2) ..._buildPriceStep(maxSeats, selected),
                            if (_error != null) ...[
                              const SizedBox(height: 10),
                              ErrorBanner(_error!),
                            ],
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteStepBody(LatLng mapCenter, DriveRoute? selected) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: SoftPanel(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Column(
              children: [
                Row(
                  children: [
                    Text('Places', style: Theme.of(context).textTheme.titleSmall),
                    const Spacer(),
                    _InfoIcon(
                      title: 'Places',
                      message:
                          'Search near your office city, within ${kMaxLocalSearchKm.round()} km. '
                          'Use the GPS pin on From for your current location. Swap flips From and To.',
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                PlaceSearchField(
                  key: _fromKey,
                  label: 'From',
                  initialText: _from?.label,
                  searchCity: _userCity,
                  nearLat: _nearLat,
                  nearLng: _nearLng,
                  onMyLocation: _useMyLocation,
                  onSelected: _onFromSelected,
                  compact: true,
                ),
                SizedBox(
                  height: 36,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Divider(height: 1),
                      Material(
                        color: AppTheme.surfaceElevated,
                        elevation: 1,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: (_from != null || _to != null) ? _swapEnds : null,
                          child: Ink(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.line),
                              color: AppTheme.surfaceElevated,
                            ),
                            child: Icon(
                              Icons.swap_vert_rounded,
                              size: 20,
                              color: (_from != null || _to != null)
                                  ? AppTheme.brandBlue
                                  : AppTheme.inkMuted,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                PlaceSearchField(
                  key: _toKey,
                  label: 'To',
                  initialText: _to?.label,
                  searchCity: _userCity,
                  nearLat: _from?.lat ?? _nearLat,
                  nearLng: _from?.lng ?? _nearLng,
                  onSelected: _onToSelected,
                  compact: true,
                ),
              ],
            ),
          ),
        ),
        if (_locating)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: ErrorBanner(_error!),
          ),
        if (_routeError != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: Text(_routeError!, style: TextStyle(color: Colors.orange.shade800, fontSize: 12)),
          ),
        const SizedBox(height: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Stack(
              children: [
                OsmMapView(
                  center: mapCenter,
                  expand: true,
                  fitToMarkers: true,
                  markers: [
                    if (_from != null) OsmMapView.pin(LatLng(_from!.lat, _from!.lng)),
                    if (_to != null)
                      OsmMapView.pin(LatLng(_to!.lat, _to!.lng), color: AppTheme.brandOrange),
                  ],
                  routes: _routes,
                  selectedRouteIndex: _selectedRoute,
                  onRouteSelected: (i) {
                    setState(() => _selectedRoute = i);
                    _recalculatePrice();
                  },
                ),
                if (_routing)
                  const Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
                if (selected != null)
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 10,
                    child: Material(
                      elevation: 2,
                      color: Colors.white.withOpacity(0.96),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                        child: Row(
                          children: [
                            Icon(
                              selected.usesLiveTraffic ? Icons.traffic_rounded : Icons.route_rounded,
                              size: 20,
                              color: AppTheme.brandBlue,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${selected.rankLabel} · ${selected.durationLabel} · ${selected.distanceLabel}',
                                style: Theme.of(context).textTheme.titleSmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            _InfoIcon(
                              title: 'Route',
                              message: _routes.length > 1
                                  ? 'Showing top routes by ETA. Tap a chip on the map to switch. Refresh updates traffic when available.'
                                  : (selected.usesLiveTraffic
                                      ? 'Live traffic ETA for this drive. Refresh to recalculate.'
                                      : 'Typical driving ETA. Refresh after traffic changes.'),
                            ),
                            IconButton(
                              tooltip: 'Refresh route',
                              onPressed: _loadRoutes,
                              icon: const Icon(Icons.refresh_rounded, size: 20),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildVehicleStep(AsyncValue<List<Vehicle>> vehiclesAsync) {
    return [
      if (_from != null && _to != null)
        SoftPanel(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.route_rounded, size: 18, color: AppTheme.brandBlue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_short(_from!.label)} → ${_short(_to!.label)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.ink),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                onPressed: () => setState(() => _step = 0),
                child: const Text('Edit'),
              ),
            ],
          ),
        ),
      const SizedBox(height: 14),
      Row(
        children: [
          const Expanded(child: SectionLabel('Your vehicle')),
          TextButton(
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            onPressed: () => context.push('/profile/vehicles'),
            child: const Text('Manage'),
          ),
        ],
      ),
      const SizedBox(height: 8),
      vehiclesAsync.when(
        data: (list) {
          if (list.isEmpty) {
            return SoftPanel(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: EmptyInline(
                text: 'No vehicles yet',
                action: 'Add one',
                onTap: () => context.push('/profile/vehicles'),
              ),
            );
          }
          return Column(
            children: [
              for (final v in list)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _VehicleChip(
                    vehicle: v,
                    selected: _vehicle?.id == v.id,
                    wide: true,
                    onTap: () {
                      setState(() {
                        _vehicle = v;
                        if (!SeatPriceEstimator.canOfferThreeBack(v.seats)) {
                          _backSeatMode = BackSeatMode.spacious2;
                        }
                      });
                      _syncSeatsDefault();
                    },
                  ),
                ),
            ],
          );
        },
        loading: () => const SoftPanel(
          padding: EdgeInsets.all(12),
          child: LinearProgressIndicator(),
        ),
        error: (e, _) => ErrorBanner(ref.read(apiClientProvider).messageFrom(e)),
      ),
      if (_vehicle != null) ...[
        const SizedBox(height: 8),
        Row(
          children: [
            const Expanded(child: SectionLabel('Back seats')),
            _InfoIcon(
              title: 'Back seats',
              message:
                  '2 in the back is roomier (comfort) and usually a higher ₹ per seat. '
                  '3 in the back shares cost across more co-riders, so ₹ per seat is typically lower.',
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final mode in [
              BackSeatMode.spacious2,
              if (SeatPriceEstimator.canOfferThreeBack(_vehicle!.seats)) BackSeatMode.standard3,
            ])
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: mode == BackSeatMode.spacious2 ? 8 : 0),
                  child: _BackSeatModeChip(
                    mode: mode,
                    selected: _backSeatMode == mode,
                    onTap: () {
                      setState(() => _backSeatMode = mode);
                      _syncSeatsDefault();
                    },
                  ),
                ),
              ),
          ],
        ),
      ],
    ];
  }

  List<Widget> _buildPriceStep(int maxSeats, DriveRoute? selected) {
    return [
      SoftPanel(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Trip summary', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            if (_from != null && _to != null)
              Text(
                '${_short(_from!.label)} → ${_short(_to!.label)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.ink),
              ),
            const SizedBox(height: 4),
            Text(
              [
                if (_vehicle != null) _vehicle!.displayName,
                _backSeatMode.title,
                if (selected != null) selected.durationLabel,
              ].join(' · '),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      SoftPanel(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          children: [
            InkWell(
              onTap: _pickDepart,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.schedule_rounded, color: AppTheme.brandBlue, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        DateFormat.MMMEd().add_jm().format(_depart.toLocal()),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    Text(
                      'Change',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.brandBlue),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 18),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _seats,
                    decoration: InputDecoration(
                      labelText: 'Seats',
                      isDense: true,
                      suffixIcon: _InfoIcon(
                        title: 'Seats to offer',
                        message: 'How many back seats you’re selling. Max for ${_backSeatMode.title} is $maxSeats.',
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _price,
                    decoration: InputDecoration(
                      labelText: '₹ / seat',
                      isDense: true,
                      suffixIcon: _InfoIcon(
                        title: 'Your price',
                        message:
                            'This is the final cash price co-riders see. A suggested guide appears below when a route is ready — you can use it or set your own amount.',
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() => _priceManual = true),
                  ),
                ),
              ],
            ),
            if (_priceEstimate != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.lightbulb_outline_rounded, size: 16, color: AppTheme.brandBlue.withOpacity(0.9)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Guide ₹${_priceEstimate!.suggestedPerSeat}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.ink),
                    ),
                  ),
                  _InfoIcon(
                    title: 'Price guide',
                    message:
                        'Based on distance, time, and how seats are shared. It’s only a suggestion — your ₹ / seat field is what gets published.',
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onPressed: () => _recalculatePrice(force: true),
                    child: const Text('Use'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    ];
  }
}

class _InfoIcon extends StatelessWidget {
  const _InfoIcon({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: title,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      icon: const Icon(Icons.info_outline_rounded, size: 18, color: AppTheme.inkMuted),
      onPressed: () {
        showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          builder: (ctx) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(ctx).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(message, style: Theme.of(ctx).textTheme.bodyMedium),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StepProgress extends StatelessWidget {
  const _StepProgress({required this.step, required this.labels});

  final int step;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                color: i <= step ? AppTheme.brandBlue : AppTheme.line,
              ),
            ),
          _StepDot(index: i, active: i == step, done: i < step, label: labels[i]),
        ],
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.index,
    required this.active,
    required this.done,
    required this.label,
  });

  final int index;
  final bool active;
  final bool done;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = active || done ? AppTheme.brandBlue : AppTheme.inkMuted;
    return Column(
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: done || active ? AppTheme.brandBlue : AppTheme.surfaceElevated,
            shape: BoxShape.circle,
            border: Border.all(color: done || active ? AppTheme.brandBlue : AppTheme.line),
          ),
          child: done
              ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
              : Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: active ? Colors.white : AppTheme.inkMuted,
                  ),
                ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
        ),
      ],
    );
  }
}

class _WizardBar extends StatelessWidget {
  const _WizardBar({
    required this.step,
    required this.stepCount,
    required this.saving,
    required this.primaryLabel,
    required this.primaryEnabled,
    required this.subtitle,
    required this.onPrimary,
    this.onBack,
  });

  final int step;
  final int stepCount;
  final bool saving;
  final String primaryLabel;
  final bool primaryEnabled;
  final String subtitle;
  final VoidCallback onPrimary;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      color: AppTheme.surfaceElevated,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              if (onBack != null) ...[
                OutlinedButton(
                  onPressed: saving ? null : onBack,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Back'),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${step + 1}/$stepCount',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.brandBlue),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: step == stepCount - 1 ? AppTheme.brandOrange : AppTheme.brandBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: (!primaryEnabled || saving) ? null : onPrimary,
                child: saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                      )
                    : Text(primaryLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackSeatModeChip extends StatelessWidget {
  const _BackSeatModeChip({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final BackSeatMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppTheme.brandOrange.withOpacity(0.12) : AppTheme.surfaceElevated,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppTheme.brandOrange : AppTheme.line,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                mode.isComfort ? Icons.airline_seat_recline_extra_rounded : Icons.event_seat_rounded,
                size: 18,
                color: selected ? AppTheme.brandOrange : AppTheme.inkMuted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  mode.title,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: selected ? AppTheme.brandOrange : AppTheme.ink,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VehicleChip extends StatelessWidget {
  const _VehicleChip({
    required this.vehicle,
    required this.selected,
    required this.onTap,
    this.wide = false,
  });

  final Vehicle vehicle;
  final bool selected;
  final VoidCallback onTap;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final v = vehicle;
    return Material(
      color: selected ? AppTheme.brandBlue.withOpacity(0.1) : AppTheme.surfaceElevated,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: wide ? double.infinity : 168,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppTheme.brandBlue : AppTheme.line,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.directions_car_filled_rounded,
                size: 20,
                color: selected ? AppTheme.brandBlue : AppTheme.inkMuted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      v.displayName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: selected ? AppTheme.brandBlue : AppTheme.ink,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${v.makeModel} · ${v.plateMasked} · ${v.seats} seats'
                      '${v.primary ? ' · primary' : ''}',
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle_rounded, size: 18, color: AppTheme.brandBlue),
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyInline extends StatelessWidget {
  const EmptyInline({
    super.key,
    required this.text,
    required this.action,
    required this.onTap,
  });

  final String text;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
        TextButton(onPressed: onTap, child: Text(action)),
      ],
    );
  }
}
