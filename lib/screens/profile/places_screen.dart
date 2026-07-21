import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:ridebuddy/models/models.dart';
import 'package:ridebuddy/providers/auth_provider.dart';
import 'package:ridebuddy/providers/location_provider.dart';
import 'package:ridebuddy/services/api_client.dart';
import 'package:ridebuddy/services/nominatim_service.dart';
import 'package:ridebuddy/services/ride_repository.dart';
import 'package:ridebuddy/theme/app_theme.dart';
import 'package:ridebuddy/widgets/common/ui_kit.dart';
import 'package:ridebuddy/widgets/maps/osm_map_view.dart';
import 'package:ridebuddy/widgets/maps/place_route_label.dart';
import 'package:ridebuddy/widgets/maps/place_search_field.dart';

class PlacesScreen extends ConsumerStatefulWidget {
  const PlacesScreen({super.key});

  @override
  ConsumerState<PlacesScreen> createState() => _PlacesScreenState();
}

class _PlacesScreenState extends ConsumerState<PlacesScreen> {
  List<SavedPlace> _places = [];
  bool _loading = true;
  String? _error;
  String? _officeCity;
  double? _mapLat;
  double? _mapLng;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final region = await ref.read(officeMapRegionProvider.future);
      final places = await ref.read(rideRepositoryProvider).savedPlaces();
      if (!mounted) return;
      setState(() {
        _officeCity = region.city;
        _mapLat = region.lat;
        _mapLng = region.lng;
        _places = places;
        final primaryOffice = _firstWhereOrNull(_places, (p) => p.kind == 'office' && p.primary)
            ?? _firstWhereOrNull(_places, (p) => p.kind == 'office');
        if (primaryOffice != null) {
          _mapLat = primaryOffice.lat;
          _mapLng = primaryOffice.lng;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = ref.read(apiClientProvider).messageFrom(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  SavedPlace? _firstWhereOrNull(List<SavedPlace> list, bool Function(SavedPlace) test) {
    for (final p in list) {
      if (test(p)) return p;
    }
    return null;
  }

  List<SavedPlace> get _homes => _places.where((p) => p.kind == 'home').toList();
  List<SavedPlace> get _offices => _places.where((p) => p.kind == 'office').toList();

  Future<void> _openEditor({SavedPlace? existing, required String kind}) async {
    final result = await showModalBottomSheet<_PlaceDraft>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _PlaceEditorSheet(
        kind: kind,
        existing: existing,
        searchCity: _officeCity,
        nearLat: _mapLat,
        nearLng: _mapLng,
      ),
    );
    if (result == null || !mounted) return;
    try {
      final repo = ref.read(rideRepositoryProvider);
      final body = {
        'kind': kind,
        'privateLabel': result.privateLabel,
        'publicShort': result.place.publicShort,
        'fullAddress': result.place.fullAddress,
        'lat': result.place.lat,
        'lng': result.place.lng,
        'primary': result.primary,
      };
      if (existing == null) {
        await repo.createSavedPlace(body);
      } else {
        await repo.updateSavedPlace(existing.id, body);
      }
      ref.invalidate(profileProvider);
      ref.invalidate(officeMapRegionProvider);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ref.read(apiClientProvider).messageFrom(e))),
      );
    }
  }

  Future<void> _delete(SavedPlace place) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove place?'),
        content: Text('Remove “${place.privateLabel}”?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(rideRepositoryProvider).deleteSavedPlace(place.id);
      ref.invalidate(profileProvider);
      ref.invalidate(officeMapRegionProvider);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ref.read(apiClientProvider).messageFrom(e))),
      );
    }
  }

  Future<void> _setPrimary(SavedPlace place) async {
    try {
      await ref.read(rideRepositoryProvider).setPrimarySavedPlace(place.id);
      ref.invalidate(profileProvider);
      ref.invalidate(officeMapRegionProvider);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ref.read(apiClientProvider).messageFrom(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final markers = [
      for (final p in _places)
        OsmMapView.pin(
          LatLng(p.lat, p.lng),
          color: p.kind == 'home' ? AppTheme.brandOrange : AppTheme.brandBlue,
          icon: p.kind == 'home' ? Icons.home : Icons.apartment,
        ),
    ];

    return SkyScaffold(
      appBar: AppBar(title: const Text('Home & Office')),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                Text(
                  'Private names are only visible to you. Others see the short area or landmark.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.inkMuted),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  ErrorBanner(_error!),
                ],
                const SizedBox(height: 16),
                _sectionHeader(
                  context,
                  title: 'Homes',
                  onAdd: () => _openEditor(kind: 'home'),
                ),
                ..._homes.map((p) => _placeCard(p)),
                if (_homes.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text('No homes yet — add one for commute defaults.'),
                  ),
                const SizedBox(height: 8),
                _sectionHeader(
                  context,
                  title: 'Offices',
                  onAdd: () => _openEditor(kind: 'office'),
                ),
                ..._offices.map((p) => _placeCard(p)),
                if (_offices.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text('No offices yet — add your workplace.'),
                  ),
                if (_mapLat != null && _mapLng != null) ...[
                  const SizedBox(height: 12),
                  SoftPanel(
                    padding: EdgeInsets.zero,
                    child: SizedBox(
                      height: 200,
                      width: double.infinity,
                      child: OsmMapView(
                        center: LatLng(_mapLat!, _mapLng!),
                        height: 200,
                        fitToMarkers: true,
                        fitPadding: const EdgeInsets.all(24),
                        markers: markers,
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _sectionHeader(BuildContext context, {required String title, required VoidCallback onAdd}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _placeCard(SavedPlace place) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SoftPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  place.kind == 'home' ? Icons.home_outlined : Icons.apartment_outlined,
                  color: place.kind == 'home' ? AppTheme.brandOrange : AppTheme.brandBlue,
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: (place.kind == 'home' ? AppTheme.brandOrange : AppTheme.brandBlue)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    place.kind == 'home' ? 'Home' : 'Office',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: place.kind == 'home' ? AppTheme.brandOrange : AppTheme.brandBlue,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(place.privateLabel, style: Theme.of(context).textTheme.titleSmall),
                ),
                if (place.primary)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.brandBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Primary',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppTheme.brandBlue,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text('Others see', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.inkMuted)),
            PlaceRouteLabel(
              title: place.publicShort,
              fullAddress: place.fullAddress,
              dense: true,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (!place.primary)
                  TextButton(
                    onPressed: () => _setPrimary(place),
                    child: const Text('Set primary'),
                  ),
                const Spacer(),
                IconButton(
                  tooltip: 'Edit',
                  onPressed: () => _openEditor(existing: place, kind: place.kind),
                  icon: const Icon(Icons.edit_outlined, size: 20),
                ),
                IconButton(
                  tooltip: 'Delete',
                  onPressed: () => _delete(place),
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceDraft {
  _PlaceDraft({
    required this.privateLabel,
    required this.place,
    required this.primary,
  });

  final String privateLabel;
  final PlaceSuggestion place;
  final bool primary;
}

class _PlaceEditorSheet extends StatefulWidget {
  const _PlaceEditorSheet({
    required this.kind,
    this.existing,
    this.searchCity,
    this.nearLat,
    this.nearLng,
  });

  final String kind;
  final SavedPlace? existing;
  final String? searchCity;
  final double? nearLat;
  final double? nearLng;

  @override
  State<_PlaceEditorSheet> createState() => _PlaceEditorSheetState();
}

class _PlaceEditorSheetState extends State<_PlaceEditorSheet> {
  late final TextEditingController _name;
  PlaceSuggestion? _place;
  late bool _primary;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(
      text: e?.privateLabel ?? (widget.kind == 'home' ? 'Home' : 'Office'),
    );
    _primary = e?.primary ?? false;
    if (e != null) {
      _place = PlaceSuggestion(
        publicShort: e.publicShort,
        fullAddress: e.fullAddress,
        privateLabel: e.privateLabel,
        lat: e.lat,
        lng: e.lng,
        savedPlaceId: e.id,
      );
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter a private name');
      return;
    }
    if (_place == null) {
      setState(() => _error = 'Pick a location from suggestions');
      return;
    }
    Navigator.pop(
      context,
      _PlaceDraft(privateLabel: name, place: _place!, primary: _primary),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.existing == null
                  ? 'Add ${widget.kind == 'home' ? 'Home' : 'Office'}'
                  : 'Edit ${widget.kind == 'home' ? 'Home' : 'Office'}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: widget.kind == 'home'
                    ? 'Private name (only you see this)'
                    : 'Private name (only you see this)',
                hintText: widget.kind == 'home' ? 'e.g. Mom’s place' : 'e.g. Mindspace',
              ),
            ),
            const SizedBox(height: 12),
            PlaceSearchField(
              label: 'Location',
              initialText: _place?.publicShort,
              searchCity: widget.searchCity,
              nearLat: widget.nearLat,
              nearLng: widget.nearLng,
              loadSavedPlaces: false,
              onSelected: (p) => setState(() {
                _place = p;
                _error = null;
              }),
            ),
            if (_place != null) ...[
              const SizedBox(height: 8),
              Text('Others will see', style: Theme.of(context).textTheme.labelSmall),
              PlaceRouteLabel(title: _place!.publicShort, fullAddress: _place!.fullAddress),
            ],
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Primary for commute defaults'),
              value: _primary,
              onChanged: (v) => setState(() => _primary = v),
            ),
            if (_error != null) ErrorBanner(_error!),
            const SizedBox(height: 8),
            PrimaryButton(label: 'Save', onPressed: _save),
          ],
        ),
      ),
    );
  }
}
