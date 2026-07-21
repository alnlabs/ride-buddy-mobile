import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ridebuddy/providers/auth_provider.dart';
import 'package:ridebuddy/services/location_service.dart';
import 'package:ridebuddy/services/nominatim_service.dart';
import 'package:ridebuddy/services/ride_repository.dart';
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
    this.quickPicks,
    this.loadSavedPlaces = true,
  });

  final String label;
  final String? initialText;
  final PlaceSelected onSelected;
  final String? searchCity;
  final double? nearLat;
  final double? nearLng;
  /// Hard cap for suggestions around [nearLat]/[nearLng] (default 100 km).
  final double maxDistanceKm;
  /// Show “Use my location” under the field (default on).
  final bool showMyLocation;
  /// Optional override; when null, reverse-geocodes current GPS automatically.
  final Future<PlaceSuggestion?> Function()? onMyLocation;
  /// Denser field chrome for wizards / tight layouts.
  final bool compact;
  /// Optional preloaded labels (homes/offices). If null and [loadSavedPlaces], fetched on focus.
  final List<PlaceSuggestion>? quickPicks;
  /// Auto-load the user’s saved homes/offices when the field is focused.
  final bool loadSavedPlaces;

  @override
  PlaceSearchFieldState createState() => PlaceSearchFieldState();
}

class PlaceSearchFieldState extends ConsumerState<PlaceSearchField> {
  late final TextEditingController _controller;
  final _focus = FocusNode();
  Timer? _debounce;
  int _searchSeq = 0;
  List<PlaceSuggestion> _results = [];
  List<PlaceSuggestion> _savedPicks = [];
  bool _savedLoaded = false;
  bool _loading = false;
  bool _focused = false;
  String? _searchError;
  PlaceSuggestion? _selected;
  bool _showFullInField = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    if (widget.quickPicks != null) {
      _savedPicks = List.of(widget.quickPicks!);
      _savedLoaded = true;
    }
    _focus.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    final focused = _focus.hasFocus;
    setState(() => _focused = focused);
    if (focused) {
      _ensureSavedPicks();
    }
  }

  @override
  void didUpdateWidget(covariant PlaceSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.quickPicks != null && widget.quickPicks != oldWidget.quickPicks) {
      _savedPicks = List.of(widget.quickPicks!);
      _savedLoaded = true;
    }
    // Don't overwrite while the user is actively typing a new search.
    if (_selected != null &&
        widget.initialText != oldWidget.initialText &&
        widget.initialText != null &&
        widget.initialText!.isNotEmpty &&
        _controller.text != widget.initialText) {
      _controller.text = widget.initialText!;
      _showFullInField = false;
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChange);
    _focus.dispose();
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _ensureSavedPicks({bool force = false}) async {
    if (!widget.loadSavedPlaces) return;
    if (_savedLoaded && !force) return;
    _savedLoaded = true;
    try {
      final places = await ref.read(rideRepositoryProvider).savedPlaces();
      if (!mounted) return;
      setState(() {
        _savedPicks = places
            .map(
              (p) => PlaceSuggestion(
                publicShort: p.publicShort,
                fullAddress: p.fullAddress,
                privateLabel: p.privateLabel,
                lat: p.lat,
                lng: p.lng,
                savedPlaceId: p.id,
                kind: p.kind,
              ),
            )
            .toList();
      });
    } catch (_) {
      // Offline / unauthenticated — ignore; search still works.
    }
  }

  void _onChanged(String value) {
    _selected = null;
    _showFullInField = false;
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

  void _setFieldText(PlaceSuggestion place, {required bool full}) {
    final short = _fieldDisplayLabel(place);
    final fullAddr = place.fullAddress?.trim();
    if (full && fullAddr != null && fullAddr.isNotEmpty) {
      _controller.text = fullAddr;
      _showFullInField = true;
    } else {
      _controller.text = short;
      _showFullInField = false;
    }
  }

  /// From/To field should show the place/area — not the private nickname "Home"/"Office".
  String _fieldDisplayLabel(PlaceSuggestion place) {
    if (place.kind == 'home' || place.kind == 'office') {
      final pub = place.publicShort.trim();
      if (pub.isNotEmpty) return pub;
    }
    return place.label;
  }

  void _pick(PlaceSuggestion place) {
    _selected = place;
    _setFieldText(place, full: false);
    setState(() {
      _results = [];
      _searchError = null;
    });
    widget.onSelected(place);
    FocusScope.of(context).unfocus();
  }

  /// Chip text: location name. Kind is already shown via the home/office icon.
  String _savedChipLabel(PlaceSuggestion p) {
    final pl = p.privateLabel?.trim();
    final generic = pl == null ||
        pl.isEmpty ||
        pl.toLowerCase() == 'home' ||
        pl.toLowerCase() == 'office';
    if (p.kind == 'home' || p.kind == 'office') {
      if (!generic) return pl;
      final pub = p.publicShort.trim();
      if (pub.isNotEmpty) return pub;
    }
    return p.label;
  }

  void applyPlace(PlaceSuggestion place) {
    _selected = place;
    _setFieldText(place, full: false);
    setState(() {
      _results = [];
      _searchError = null;
    });
    widget.onSelected(place);
  }

  void clear() {
    _controller.clear();
    _selected = null;
    _showFullInField = false;
    setState(() {
      _results = [];
      _searchError = null;
    });
    // Keep focus so saved labels stay visible for re-pick.
    _focus.requestFocus();
  }

  Future<PlaceSuggestion?> _resolveMyLocation() async {
    if (widget.onMyLocation != null) {
      final place = await widget.onMyLocation!();
      if (place != null) return place;
      final status = await LocationService.currentPositionDetailed(openSettingsIfBlocked: false);
      throw _GpsException(
        status.isOk ? 'Couldn’t label this location — try again' : status.message,
      );
    }
    final result = await LocationService.currentPositionDetailed();
    if (!result.isOk) {
      throw _GpsException(result.message);
    }
    final pos = result.position!;
    final detailed =
        await ref.read(nominatimServiceProvider).reverseDetailed(pos.latitude, pos.longitude);
    if (detailed != null) return detailed;
    // GPS worked but reverse-geocode failed — still usable for routing.
    return PlaceSuggestion(
      publicShort: 'Current location',
      fullAddress:
          '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}',
      lat: pos.latitude,
      lng: pos.longitude,
    );
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
    } on _GpsException catch (e) {
      if (!mounted) return;
      setState(() => _searchError = e.message);
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

  bool get _hasFullToggle {
    final s = _selected;
    if (s == null) return false;
    final full = s.fullAddress?.trim();
    return full != null && full.isNotEmpty && full != s.label;
  }

  /// Saved labels before typing; hide once the user is searching.
  bool get _showSavedLabels {
    if (!_focused || _savedPicks.isEmpty) return false;
    if (_results.isNotEmpty) return false;
    final q = _controller.text.trim();
    // Empty, or still showing the selected label (user tapped field to change).
    if (q.length < 2) return true;
    if (_selected != null && (q == _selected!.label || q == (_selected!.fullAddress ?? ''))) {
      return true;
    }
    return false;
  }

  String get _helperCopy {
    final l = widget.label.trim().toLowerCase();
    if (l == 'from') return 'Where this trip starts';
    if (l == 'to') return 'Where this trip ends';
    return 'Search an area or landmark';
  }

  String get _hintCopy {
    if (_savedPicks.isNotEmpty) {
      return 'Type a place, or pick one of yours below';
    }
    return 'e.g. office gate, metro, neighbourhood';
  }

  IconData get _leadingIcon {
    final l = widget.label.trim().toLowerCase();
    if (l == 'from') return Icons.trip_origin_rounded;
    if (l == 'to') return Icons.flag_rounded;
    return Icons.place_outlined;
  }

  @override
  Widget build(BuildContext context) {
    // Reload Home/Office chips when places change (IndexedStack keeps this field alive).
    ref.listen(profileProvider, (prev, next) {
      if (!widget.loadSavedPlaces) return;
      next.whenData((_) {
        _savedLoaded = false;
        if (_focused) _ensureSavedPicks(force: true);
      });
    });

    final hasText = _controller.text.isNotEmpty;
    final theme = Theme.of(context);
    final focused = _focused;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.label,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
            color: AppTheme.ink,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          _helperCopy,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppTheme.inkMuted,
            height: 1.25,
          ),
        ),
        SizedBox(height: widget.compact ? 8 : 10),
        AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            color: AppTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: focused ? AppTheme.brandBlue : AppTheme.line,
              width: focused ? 1.5 : 1,
            ),
            boxShadow: focused
                ? [
                    BoxShadow(
                      color: AppTheme.brandBlue.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focus,
            minLines: 1,
            maxLines: 3,
            textInputAction: TextInputAction.search,
            onSubmitted: (v) => _search(v),
            onTap: () {
              _ensureSavedPicks();
              setState(() {});
            },
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              hintText: _hintCopy,
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.inkMuted.withOpacity(0.85),
                fontWeight: FontWeight.w500,
              ),
              isDense: widget.compact,
              contentPadding: EdgeInsets.fromLTRB(
                4,
                widget.compact ? 12 : 14,
                4,
                widget.compact ? 12 : 14,
              ),
              prefixIcon: Icon(
                _leadingIcon,
                size: 22,
                color: focused ? AppTheme.brandBlue : AppTheme.inkMuted,
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 40),
              suffixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              suffixIcon: _loading
                  ? const UnconstrainedBox(
                      child: Padding(
                        padding: EdgeInsets.only(right: 10),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  : hasText
                      ? IconButton(
                          tooltip: 'Clear',
                          onPressed: clear,
                          icon: const Icon(Icons.close_rounded, size: 20),
                          visualDensity: VisualDensity.compact,
                        )
                      : null,
            ),
            onChanged: (v) {
              setState(() {});
              _onChanged(v);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Wrap(
            spacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (widget.showMyLocation)
                TextButton.icon(
                  onPressed: _loading ? null : _useMyLocation,
                  icon: const Icon(Icons.my_location_rounded, size: 15),
                  label: const Text('My location'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    foregroundColor: AppTheme.brandBlue,
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              if (_hasFullToggle)
                TextButton(
                  onPressed: () {
                    final place = _selected!;
                    setState(() {
                      _setFieldText(place, full: !_showFullInField);
                    });
                  },
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    foregroundColor: AppTheme.inkMuted,
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  child: Text(_showFullInField ? 'Short name' : 'Full address'),
                ),
            ],
          ),
        ),
        if (_searchError != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _searchError!,
              style: TextStyle(color: Colors.orange.shade800, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        if (_showSavedLabels) _savedLabelsPanel(context),
        if (_results.isNotEmpty) _searchResultsPanel(context),
      ],
    );
  }

  Widget _savedLabelsPanel(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Your places',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppTheme.inkMuted,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in _savedPicks)
                ChoiceChip(
                  avatar: Icon(
                    p.kind == 'office' ? Icons.apartment_outlined : Icons.home_outlined,
                    size: 16,
                    color: AppTheme.brandBlue,
                  ),
                  label: Text(_savedChipLabel(p)),
                  selected: _selected?.savedPlaceId != null && _selected?.savedPlaceId == p.savedPlaceId,
                  onSelected: (_) => _pick(p),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _searchResultsPanel(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.line),
      ),
      constraints: const BoxConstraints(maxHeight: 220),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: _results.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final p = _results[i];
          return ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            title: Text(p.publicShort, maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: p.fullAddress != null && p.fullAddress != p.publicShort
                ? Text(
                    p.fullAddress!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted),
                  )
                : null,
            onTap: () => _pick(p),
          );
        },
      ),
    );
  }
}

class _GpsException implements Exception {
  _GpsException(this.message);
  final String message;
}
