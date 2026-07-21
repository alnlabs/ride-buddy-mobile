import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ridebuddy/providers/location_provider.dart';
import 'package:ridebuddy/services/api_client.dart';
import 'package:ridebuddy/services/location_service.dart';
import 'package:ridebuddy/services/nominatim_service.dart';
import 'package:ridebuddy/services/ride_repository.dart';
import 'package:ridebuddy/theme/app_theme.dart';
import 'package:ridebuddy/widgets/common/ui_kit.dart';
import 'package:ridebuddy/widgets/maps/place_search_field.dart';
import 'package:ridebuddy/widgets/ride/recurrence_picker.dart';

class PostNeedScreen extends ConsumerStatefulWidget {
  const PostNeedScreen({super.key});

  @override
  ConsumerState<PostNeedScreen> createState() => _PostNeedScreenState();
}

class _PostNeedScreenState extends ConsumerState<PostNeedScreen> {
  final _fromKey = GlobalKey<PlaceSearchFieldState>();
  PlaceSuggestion? _from;
  PlaceSuggestion? _to;
  String? _userCity;
  double? _nearLat;
  double? _nearLng;
  DateTime _depart = DateTime.now().add(const Duration(hours: 1));
  int _seats = 1;
  bool _comfort = false;
  bool _saving = false;
  String? _error;
  bool _recurring = false;
  RecurrenceFrequency _frequency = RecurrenceFrequency.weekdays;
  Set<int> _days = {1, 2, 3, 4, 5};
  int _dayOfMonth = DateTime.now().day;
  TimeOfDay _departTime = TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 1)));

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
          if (hour < 15) {
            _from = region.home;
            _to = region.office;
          } else {
            _from = region.office;
            _to = region.home;
          }
        }
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final from = _from;
        if (from != null) _fromKey.currentState?.applyPlace(from);
      });
    } catch (_) {}
  }

  Future<PlaceSuggestion?> _useMyLocation() async {
    final result = await LocationService.currentPositionDetailed();
    if (!result.isOk) return null;
    final pos = result.position!;
    final place = await ref.read(nominatimServiceProvider).reverseDetailed(pos.latitude, pos.longitude) ??
        PlaceSuggestion(
          publicShort: 'Current location',
          fullAddress:
              '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}',
          lat: pos.latitude,
          lng: pos.longitude,
        );
    if (mounted) {
      setState(() {
        _userCity = place.city;
        _nearLat = pos.latitude;
        _nearLng = pos.longitude;
      });
    }
    return place;
  }

  Future<void> _pickWhen() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _depart.isBefore(now) ? now : _depart,
      firstDate: now,
      lastDate: now.add(const Duration(hours: 24)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_depart),
    );
    if (time == null || !mounted) return;
    setState(() {
      _depart = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      _departTime = time;
    });
  }

  Future<void> _pickRecurringTime() async {
    final time = await showTimePicker(context: context, initialTime: _departTime);
    if (time == null || !mounted) return;
    setState(() => _departTime = time);
  }

  Future<void> _submit() async {
    if (_from == null || _to == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick From and To from suggestions')),
      );
      return;
    }
    if (!NominatimService.withinLocalTrip(_from!.lat, _from!.lng, _to!.lat, _to!.lng)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('To must be within ${kMaxLocalSearchKm.round()} km of From')),
      );
      return;
    }
    if (_recurring &&
        (_frequency == RecurrenceFrequency.weekly || _frequency == RecurrenceFrequency.customDays) &&
        _days.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick at least one day')),
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final places = {
        'originLat': _from!.lat,
        'originLng': _from!.lng,
        'originLabel': _from!.publicShort,
        'originPublicShort': _from!.publicShort,
        'originFullAddress': _from!.fullAddress,
        'originPrivateLabel': _from!.privateLabel,
        'destinationLat': _to!.lat,
        'destinationLng': _to!.lng,
        'destinationLabel': _to!.publicShort,
        'destinationPublicShort': _to!.publicShort,
        'destinationFullAddress': _to!.fullAddress,
        'destinationPrivateLabel': _to!.privateLabel,
      };
      if (_recurring) {
        await ref.read(rideRepositoryProvider).createSchedule({
          'kind': 'need',
          'frequency': _frequency.apiValue,
          if (_frequency == RecurrenceFrequency.weekly || _frequency == RecurrenceFrequency.customDays)
            'daysOfWeek': _days.toList()..sort(),
          if (_frequency == RecurrenceFrequency.monthly) 'dayOfMonth': _dayOfMonth,
          'departLocalTime':
              '${_departTime.hour.toString().padLeft(2, '0')}:${_departTime.minute.toString().padLeft(2, '0')}:00',
          'timezone': 'Asia/Kolkata',
          'seatsNeeded': _seats,
          'comfortPreferred': _comfort,
          ...places,
        });
        if (!mounted) return;
        context.go('/ride/schedules');
      } else {
        final need = await ref.read(rideRepositoryProvider).createNeed({
          ...places,
          'departAt': _depart.toUtc().toIso8601String(),
          'seatsNeeded': _seats,
          'comfortPreferred': _comfort,
        });
        if (!mounted) return;
        context.pushReplacement('/ride/need/${need.id}');
      }
    } catch (e) {
      setState(() => _error = ref.read(apiClientProvider).messageFrom(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SkyScaffold(
      appBar: AppBar(title: const Text('Need a ride')),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Text(
            'Post where you’re going — hosts nearby can offer a seat, and you’ll see matching rides to book.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.inkMuted),
          ),
          const SizedBox(height: 16),
          PlaceSearchField(
            key: _fromKey,
            label: 'From',
            initialText: _from?.fieldLabel,
            searchCity: _userCity,
            nearLat: _nearLat,
            nearLng: _nearLng,
            onMyLocation: _useMyLocation,
            onSelected: (p) => setState(() => _from = p),
          ),
          const SizedBox(height: 10),
          PlaceSearchField(
            label: 'To',
            initialText: _to?.fieldLabel,
            searchCity: _userCity,
            nearLat: _from?.lat ?? _nearLat,
            nearLng: _from?.lng ?? _nearLng,
            onSelected: (p) => setState(() => _to = p),
          ),
          const SizedBox(height: 12),
          RecurrencePicker(
            recurring: _recurring,
            onRecurringChanged: (v) => setState(() => _recurring = v),
            frequency: _frequency,
            onFrequencyChanged: (f) => setState(() => _frequency = f),
            selectedDays: _days,
            onDaysChanged: (d) => setState(() => _days = d),
            dayOfMonth: _dayOfMonth,
            onDayOfMonthChanged: (d) => setState(() => _dayOfMonth = d),
            departTime: _departTime,
            onDepartTimePressed: _pickRecurringTime,
          ),
          if (!_recurring) ...[
            const SizedBox(height: 12),
            SoftPanel(
              onTap: _pickWhen,
              child: Row(
                children: [
                  const Icon(Icons.schedule_rounded, color: AppTheme.brandBlue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('When', style: Theme.of(context).textTheme.labelLarge),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat.MMMd().add_jm().format(_depart),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppTheme.inkMuted),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          SoftPanel(
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(child: Text('Seats needed')),
                    ...[1, 2, 3].map((n) {
                      final selected = _seats == n;
                      return Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: ChoiceChip(
                          label: Text('$n'),
                          selected: selected,
                          onSelected: (_) => setState(() => _seats = n),
                        ),
                      );
                    }),
                  ],
                ),
                const Divider(height: 20),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Prefer comfort (max 2 in back)'),
                  value: _comfort,
                  onChanged: (v) => setState(() => _comfort = v),
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            ErrorBanner(_error!),
          ],
          const SizedBox(height: 18),
          PrimaryButton(
            label: _saving
                ? 'Saving…'
                : (_recurring ? 'Save schedule' : 'Post request'),
            loading: _saving,
            icon: Icons.hail_rounded,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
