import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:ridebuddy/providers/auth_provider.dart';
import 'package:ridebuddy/providers/location_provider.dart';
import 'package:ridebuddy/services/nominatim_service.dart';
import 'package:ridebuddy/services/ride_repository.dart';
import 'package:ridebuddy/theme/app_theme.dart';
import 'package:ridebuddy/widgets/common/ui_kit.dart';
import 'package:ridebuddy/widgets/maps/osm_map_view.dart';
import 'package:ridebuddy/widgets/maps/place_search_field.dart';

class PlacesScreen extends ConsumerStatefulWidget {
  const PlacesScreen({super.key});

  @override
  ConsumerState<PlacesScreen> createState() => _PlacesScreenState();
}

class _PlacesScreenState extends ConsumerState<PlacesScreen> {
  PlaceSuggestion? _home;
  PlaceSuggestion? _office;
  String? _officeCity;
  double? _mapLat;
  double? _mapLng;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfilePlaces());
  }

  Future<void> _loadProfilePlaces() async {
    try {
      final region = await ref.read(officeMapRegionProvider.future);
      if (!mounted) return;
      setState(() {
        _officeCity = region.city;
        _mapLat = region.lat;
        _mapLng = region.lng;
        _home = region.home;
        _office = region.office;
      });
    } catch (_) {
      try {
        final p = await ref.read(profileProvider.future);
        if (!mounted) return;
        setState(() {
          if (p.homeLat != null) {
            _home = PlaceSuggestion(label: p.homeLabel ?? 'Home', lat: p.homeLat!, lng: p.homeLng!);
          }
          if (p.officeLat != null) {
            _office = PlaceSuggestion(label: p.officeLabel ?? 'Office', lat: p.officeLat!, lng: p.officeLng!);
            _mapLat = p.officeLat;
            _mapLng = p.officeLng;
          }
        });
      } catch (_) {}
    }
  }

  Future<void> _save() async {
    if (_home == null || _office == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pick home and office')));
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(rideRepositoryProvider).updatePlaces({
        'homeLat': _home!.lat,
        'homeLng': _home!.lng,
        'homeLabel': _home!.label,
        'officeLat': _office!.lat,
        'officeLng': _office!.lng,
        'officeLabel': _office!.label,
      });
      ref.invalidate(profileProvider);
      ref.invalidate(officeMapRegionProvider);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final center = LatLng(
      _office?.lat ?? _mapLat ?? _home?.lat ?? 17.385,
      _office?.lng ?? _mapLng ?? _home?.lng ?? 78.4867,
    );
    return SkyScaffold(
      appBar: AppBar(title: const Text('Home & Office')),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          if (_officeCity != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(Icons.apartment_rounded, size: 18, color: AppTheme.brandOrange.withOpacity(0.9)),
                  const SizedBox(width: 6),
                  Text(
                    'Map · $_officeCity',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppTheme.brandOrange),
                  ),
                ],
              ),
            ),
          PlaceSearchField(
            label: 'Home',
            initialText: _home?.label,
            searchCity: _officeCity,
            nearLat: _mapLat,
            nearLng: _mapLng,
            onSelected: (p) => setState(() => _home = p),
          ),
          const SizedBox(height: 12),
          PlaceSearchField(
            label: 'Office',
            initialText: _office?.label,
            searchCity: _officeCity,
            nearLat: _mapLat,
            nearLng: _mapLng,
            onSelected: (p) => setState(() {
              _office = p;
              _officeCity = p.city ?? _officeCity;
              _mapLat = p.lat;
              _mapLng = p.lng;
            }),
          ),
          const SizedBox(height: 16),
          OsmMapView(
            center: center,
            height: 240,
            fitToMarkers: _home != null && _office != null,
            markers: [
              if (_home != null) OsmMapView.pin(LatLng(_home!.lat, _home!.lng), color: Colors.blue),
              if (_office != null)
                OsmMapView.pin(LatLng(_office!.lat, _office!.lng), color: Colors.orange, icon: Icons.apartment),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Map defaults to your office city',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Save places',
            loading: _saving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
