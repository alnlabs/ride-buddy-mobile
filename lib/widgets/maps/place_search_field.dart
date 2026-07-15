import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ridebuddy/services/location_service.dart';
import 'package:ridebuddy/services/nominatim_service.dart';
import 'package:ridebuddy/theme/app_theme.dart';

typedef PlaceSelected = void Function(PlaceSuggestion place);

class PlaceSearchField extends ConsumerStatefulWidget {
  const PlaceSearchField({
    super.key,
    required this.label,
    this.initialText,
    required this.onSelected,
    this.searchCity,
    this.nearLat,
    this.nearLng,
    this.maxDistanceKm = kMaxLocalSearchKm,
    this.showMyLocation = true,
    this.onMyLocation,
    this.compact = false,
  });

  final String label;
  final String? initialText;
  final PlaceSelected onSelected;
  final String? searchCity;
  final double? nearLat;
  final double? nearLng;
  /// Hard cap for suggestions around [nearLat]/[nearLng] (default 100 km).
  final double maxDistanceKm;
  /// Show the GPS pin on every location field (default on).
  final bool showMyLocation;
  /// Optional override; when null, reverse-geocodes current GPS automatically.
  final Future<PlaceSuggestion?> Function()? onMyLocation;
  /// Denser field chrome for wizards / tight layouts.
  final bool compact;

  @override
  PlaceSearchFieldState createState() => PlaceSearchFieldState();
}

class PlaceSearchFieldState extends ConsumerState<PlaceSearchField> {
  late final TextEditingController _controller;
  Timer? _debounce;
  int _searchSeq = 0;
  List<PlaceSuggestion> _results = [];
  bool _loading = false;
  String? _searchError;
  PlaceSuggestion? _selected;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void didUpdateWidget(covariant PlaceSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Don't overwrite while the user is actively typing a new search.
    if (_selected != null &&
        widget.initialText != oldWidget.initialText &&
        widget.initialText != null &&
        widget.initialText!.isNotEmpty &&
        _controller.text != widget.initialText) {
      _controller.text = widget.initialText!;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _selected = null;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(value));
  }

  Future<void> _search(String value) async {
    final trimmed = value.trim();
    if (trimmed.length < 2) {
      setState(() {
        _results = [];
        _searchError = null;
        _loading = false;
      });
      return;
    }
    final seq = ++_searchSeq;
    setState(() {
      _loading = true;
      _searchError = null;
    });
    try {
      final list = await ref.read(nominatimServiceProvider).search(
            trimmed,
            city: widget.searchCity,
            nearLat: widget.nearLat,
            nearLng: widget.nearLng,
            maxDistanceKm: widget.maxDistanceKm,
          );
      if (!mounted || seq != _searchSeq) return;
      setState(() {
        _results = list;
        _searchError = list.isEmpty
            ? 'No nearby places for "$trimmed" — try a clearer area name'
            : null;
      });
    } catch (e) {
      if (!mounted || seq != _searchSeq) return;
      setState(() {
        _results = [];
        _searchError = 'Search failed — check internet and try again';
      });
    } finally {
      if (mounted && seq == _searchSeq) setState(() => _loading = false);
    }
  }

  void _pick(PlaceSuggestion place) {
    _controller.text = place.label;
    _selected = place;
    setState(() {
      _results = [];
      _searchError = null;
    });
    widget.onSelected(place);
    FocusScope.of(context).unfocus();
  }

  void applyPlace(PlaceSuggestion place) {
    _controller.text = place.label;
    _selected = place;
    setState(() {
      _results = [];
      _searchError = null;
    });
    widget.onSelected(place);
  }

  void clear() {
    _controller.clear();
    _selected = null;
    setState(() {
      _results = [];
      _searchError = null;
    });
  }

  Future<PlaceSuggestion?> _resolveMyLocation() async {
    if (widget.onMyLocation != null) {
      return widget.onMyLocation!();
    }
    final pos = await LocationService.currentPosition();
    if (pos == null) return null;
    return ref.read(nominatimServiceProvider).reverseDetailed(pos.latitude, pos.longitude);
  }

  Future<void> _useMyLocation() async {
    setState(() {
      _loading = true;
      _searchError = null;
    });
    try {
      final place = await _resolveMyLocation();
      if (!mounted) return;
      if (place == null) {
        setState(() {
          _searchError = 'Couldn’t get GPS — enable location and try again';
        });
        return;
      }
      applyPlace(place);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _searchError = 'Location lookup failed — check GPS and internet';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<PlaceSuggestion?> resolveSelection() async {
    if (_selected != null) return _selected;
    final text = _controller.text.trim();
    if (text.length < 2) return null;
    final list = await ref.read(nominatimServiceProvider).search(
          text,
          city: widget.searchCity,
          nearLat: widget.nearLat,
          nearLng: widget.nearLng,
          maxDistanceKm: widget.maxDistanceKm,
        );
    if (list.isEmpty) return null;
    _pick(list.first);
    return list.first;
  }

  @override
  Widget build(BuildContext context) {
    final help = widget.nearLat != null
        ? (widget.searchCity != null
            ? 'Suggestions near ${widget.searchCity}, within ${widget.maxDistanceKm.round()} km. Tap the GPS pin to use your current location.'
            : 'Suggestions within ${widget.maxDistanceKm.round()} km of your area. Tap the GPS pin to use your current location.')
        : 'Type 2+ characters to search, or tap the GPS pin for your current location.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          textInputAction: TextInputAction.search,
          onSubmitted: (v) => _search(v),
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: 'e.g. Hitec City, Gachibowli',
            isDense: widget.compact,
            contentPadding: widget.compact
                ? const EdgeInsets.symmetric(horizontal: 12, vertical: 12)
                : null,
            suffixIcon: _loading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!widget.compact)
                        IconButton(
                          tooltip: 'About this field',
                          onPressed: () => _showHelp(context, help),
                          icon: const Icon(Icons.info_outline_rounded, size: 20),
                          visualDensity: VisualDensity.compact,
                        ),
                      if (widget.showMyLocation)
                        IconButton(
                          tooltip: 'Use my current location',
                          onPressed: _useMyLocation,
                          icon: const Icon(Icons.my_location_rounded),
                          visualDensity: widget.compact ? VisualDensity.compact : null,
                        ),
                      IconButton(
                        tooltip: 'Search',
                        onPressed: () => _search(_controller.text),
                        icon: const Icon(Icons.search_rounded),
                        visualDensity: widget.compact ? VisualDensity.compact : null,
                      ),
                    ],
                  ),
          ),
          onChanged: _onChanged,
        ),
        if (_searchError != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              _searchError!,
              style: TextStyle(color: Colors.orange.shade800, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        if (_results.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.line),
            ),
            constraints: const BoxConstraints(maxHeight: 240),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _results.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final p = _results[i];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.place_outlined, size: 20, color: AppTheme.brandBlue),
                  title: Text(p.label, maxLines: 2, overflow: TextOverflow.ellipsis),
                  onTap: () => _pick(p),
                );
              },
            ),
          ),
      ],
    );
  }

  void _showHelp(BuildContext context, String message) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.label, style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(message, style: Theme.of(ctx).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
