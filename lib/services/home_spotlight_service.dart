import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ridebuddy/data/home_spotlights.dart';
import 'package:ridebuddy/models/home_spotlight.dart';
import 'package:shared_preferences/shared_preferences.dart';

final homeSpotlightServiceProvider = Provider((ref) => HomeSpotlightService());

/// Daily Home spotlight: one tip or quote, popup once, then pinned card.
class HomeSpotlightService {
  HomeSpotlightService();

  static const _enabledKey = 'app_tips_enabled';
  static const _spotlightIdKey = 'spotlight_id';
  static const _spotlightDateKey = 'spotlight_date';
  static const _popupDateKey = 'spotlight_popup_date';
  static const _cardDismissedDateKey = 'spotlight_card_dismissed_date';
  static const _lastIdKey = 'spotlight_last_id';

  static const _quoteChance = 0.25;

  static final _rng = Random();
  static final _dayFmt = DateFormat('yyyy-MM-dd');

  SharedPreferences? _prefs;
  bool _prefsUnavailable = false;

  /// In-memory fallback when native prefs channel is down (e.g. after hot restart).
  final Map<String, String> _memory = {};
  HomeSpotlight? _sessionSpotlight;
  String? _sessionSpotlightDate;
  bool _sessionPopupShown = false;
  bool _sessionCardDismissed = false;

  String _today() => _dayFmt.format(DateTime.now());

  Future<SharedPreferences?> _loadPrefs() async {
    if (_prefsUnavailable) return null;
    if (_prefs != null) return _prefs;
    try {
      _prefs = await SharedPreferences.getInstance();
      return _prefs;
    } on PlatformException catch (e, st) {
      debugPrint('HomeSpotlightService: SharedPreferences unavailable ($e)');
      debugPrint('$st');
      _prefsUnavailable = true;
      return null;
    } catch (e, st) {
      debugPrint('HomeSpotlightService: prefs error ($e)');
      debugPrint('$st');
      _prefsUnavailable = true;
      return null;
    }
  }

  Future<String?> _getString(String key) async {
    final prefs = await _loadPrefs();
    if (prefs != null) return prefs.getString(key);
    return _memory[key];
  }

  Future<void> _setString(String key, String value) async {
    final prefs = await _loadPrefs();
    if (prefs != null) {
      await prefs.setString(key, value);
      return;
    }
    _memory[key] = value;
  }

  Future<void> _remove(String key) async {
    final prefs = await _loadPrefs();
    if (prefs != null) {
      await prefs.remove(key);
      return;
    }
    _memory.remove(key);
  }

  Future<bool> _getBool(String key, {required bool defaultValue}) async {
    final prefs = await _loadPrefs();
    if (prefs != null) return prefs.getBool(key) ?? defaultValue;
    final raw = _memory[key];
    if (raw == 'true') return true;
    if (raw == 'false') return false;
    return defaultValue;
  }

  Future<void> _setBool(String key, bool value) async {
    final prefs = await _loadPrefs();
    if (prefs != null) {
      await prefs.setBool(key, value);
      return;
    }
    _memory[key] = value.toString();
  }

  Future<bool> tipsEnabled() async {
    try {
      return await _getBool(_enabledKey, defaultValue: true);
    } catch (_) {
      return true;
    }
  }

  Future<void> setTipsEnabled(bool enabled) async {
    try {
      await _setBool(_enabledKey, enabled);
    } catch (_) {}
  }

  Future<HomeSpotlight?> todaySpotlight() async {
    try {
      if (!await tipsEnabled()) return null;

      final today = _today();
      final storedDate = await _getString(_spotlightDateKey);
      final storedId = await _getString(_spotlightIdKey);

      if (storedDate == today && storedId != null) {
        final cached = HomeSpotlightCatalog.byId(storedId);
        if (cached != null) {
          _sessionSpotlight = cached;
          _sessionSpotlightDate = today;
          return cached;
        }
      }

      if (_prefsUnavailable &&
          _sessionSpotlightDate == today &&
          _sessionSpotlight != null) {
        return _sessionSpotlight;
      }

      final lastId = await _getString(_lastIdKey);
      final pick = _pickNew(lastId);
      await _setString(_spotlightIdKey, pick.id);
      await _setString(_spotlightDateKey, today);
      await _setString(_lastIdKey, pick.id);
      if (storedDate != today) {
        await _remove(_popupDateKey);
        await _remove(_cardDismissedDateKey);
        _sessionPopupShown = false;
        _sessionCardDismissed = false;
      }
      _sessionSpotlight = pick;
      _sessionSpotlightDate = today;
      return pick;
    } catch (e, st) {
      debugPrint('HomeSpotlightService.todaySpotlight failed: $e');
      debugPrint('$st');
      return _sessionSpotlight ?? _pickNew(null);
    }
  }

  HomeSpotlight _pickNew(String? lastId) {
    final wantQuote = _rng.nextDouble() < _quoteChance;
    var pool = wantQuote
        ? List<HomeSpotlight>.of(HomeSpotlightCatalog.quotes)
        : List<HomeSpotlight>.of(HomeSpotlightCatalog.tips);

    if (lastId != null && pool.length > 1) {
      pool = pool.where((s) => s.id != lastId).toList();
    }
    if (pool.isEmpty) {
      pool = List.of(HomeSpotlightCatalog.tips);
      if (lastId != null && pool.length > 1) {
        pool = pool.where((s) => s.id != lastId).toList();
      }
    }
    return pool[_rng.nextInt(pool.length)];
  }

  Future<bool> shouldShowPopup() async {
    try {
      if (!await tipsEnabled()) return false;
      if (_prefsUnavailable) return !_sessionPopupShown;
      final shown = await _getString(_popupDateKey);
      return shown != _today();
    } catch (_) {
      return !_sessionPopupShown;
    }
  }

  Future<void> markPopupShown() async {
    try {
      _sessionPopupShown = true;
      await _setString(_popupDateKey, _today());
    } catch (_) {
      _sessionPopupShown = true;
    }
  }

  Future<bool> cardDismissedToday() async {
    try {
      if (_prefsUnavailable) return _sessionCardDismissed;
      return await _getString(_cardDismissedDateKey) == _today();
    } catch (_) {
      return _sessionCardDismissed;
    }
  }

  Future<void> dismissCard() async {
    try {
      _sessionCardDismissed = true;
      await _setString(_cardDismissedDateKey, _today());
    } catch (_) {
      _sessionCardDismissed = true;
    }
  }

  Future<bool> shouldShowCard() async {
    try {
      if (!await tipsEnabled()) return false;
      return !await cardDismissedToday();
    } catch (_) {
      return !_sessionCardDismissed;
    }
  }

  List<HomeSpotlight> allTips() => List.unmodifiable(HomeSpotlightCatalog.tips);

  List<HomeSpotlight> allQuotes() => List.unmodifiable(HomeSpotlightCatalog.quotes);

  List<HomeSpotlight> tipsForCategory(String category) =>
      HomeSpotlightCatalog.tips.where((t) => t.category == category).toList();
}
