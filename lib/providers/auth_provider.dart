import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ridebuddy/models/models.dart';
import 'package:ridebuddy/providers/ride_hub_focus_provider.dart';
import 'package:ridebuddy/services/api_client.dart';

final authStateProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref);
});

class AuthState {
  const AuthState({
    this.token,
    this.userId,
    this.phone,
    this.displayName,
    this.loading = false,
    this.initializing = false,
  });

  final String? token;
  final String? userId;
  final String? phone;
  final String? displayName;
  final bool loading;
  final bool initializing;

  bool get isAuthenticated => token != null && token!.isNotEmpty;

  AuthState copyWith({
    String? token,
    String? userId,
    String? phone,
    String? displayName,
    bool? loading,
    bool? initializing,
    bool clear = false,
  }) {
    if (clear) {
      return const AuthState();
    }
    return AuthState(
      token: token ?? this.token,
      userId: userId ?? this.userId,
      phone: phone ?? this.phone,
      displayName: displayName ?? this.displayName,
      loading: loading ?? this.loading,
      initializing: initializing ?? this.initializing,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._ref) : super(const AuthState(initializing: true)) {
    _restore();
    // Listen after this provider finishes creating — avoids circular dependency
    // with apiClient / session-expired during AuthController construction.
    Future.microtask(() {
      if (!mounted) return;
      _ref.listen<int>(authSessionExpiredProvider, (prev, next) {
        if (prev != null && next > prev) {
          _forceSignedOut();
        }
      });
    });
  }

  final Ref _ref;

  /// Clear UI focus only — do NOT invalidate profileProvider here.
  /// profileProvider watches auth userId; invalidating it from AuthController
  /// causes Riverpod circular dependency on OTP continue / login.
  void _clearSessionUi() {
    try {
      _ref.read(rideHubFocusProvider.notifier).state = null;
    } catch (_) {}
  }

  Future<void> _forceSignedOut() async {
    try {
      await _ref.read(secureStorageProvider).deleteAll();
    } catch (_) {}
    _clearSessionUi();
    if (!mounted) return;
    state = const AuthState();
  }

  Future<void> _restore() async {
    try {
      final storage = _ref.read(secureStorageProvider);
      final token = await storage.read(key: 'access_token');
      final userId = await storage.read(key: 'user_id');
      final phone = await storage.read(key: 'phone');
      final name = await storage.read(key: 'display_name');
      if (!mounted) return;
      if (token != null && token.isNotEmpty) {
        state = AuthState(
          token: token,
          userId: userId,
          phone: phone,
          displayName: name,
        );
      } else {
        state = const AuthState();
      }
    } catch (_) {
      if (mounted) state = const AuthState();
    }
  }

  /// Returns whether the UI should collect a display name (new / placeholder profile).
  Future<bool> requestOtp(String phone) async {
    final api = _ref.read(apiClientProvider);
    final res = await api.dio.post('/auth/otp/request', data: {'phone': phone});
    final data = res.data as Map<String, dynamic>;
    return data['needsDisplayName'] == true;
  }

  Future<void> verifyOtp(String phone, String code, {String? displayName}) async {
    final api = _ref.read(apiClientProvider);
    final res = await api.dio.post('/auth/otp/verify', data: {
      'phone': phone,
      'code': code,
      if (displayName != null && displayName.isNotEmpty) 'displayName': displayName,
    });
    final data = res.data as Map<String, dynamic>;
    final storage = _ref.read(secureStorageProvider);

    await storage.write(key: 'access_token', value: data['accessToken'] as String);
    await storage.write(key: 'refresh_token', value: data['refreshToken'] as String);
    await storage.write(key: 'user_id', value: data['userId'] as String);
    await storage.write(key: 'phone', value: data['phone'] as String);
    await storage.write(key: 'display_name', value: data['displayName'] as String? ?? '');

    _clearSessionUi();
    if (!mounted) return;
    // userId change refreshes profile/vehicles/trips (they watch auth userId).
    state = AuthState(
      token: data['accessToken'] as String,
      userId: data['userId'] as String,
      phone: data['phone'] as String,
      displayName: data['displayName'] as String?,
    );
  }

  Future<void> logout() async {
    await _ref.read(secureStorageProvider).deleteAll();
    _clearSessionUi();
    if (!mounted) return;
    state = const AuthState();
  }
}

final profileProvider = FutureProvider.autoDispose<Profile>((ref) async {
  final userId = ref.watch(authStateProvider.select((s) => s.userId));
  if (userId == null || userId.isEmpty) {
    throw Exception('Not signed in');
  }
  final api = ref.read(apiClientProvider);
  final res = await api.dio.get('/profile/me');
  return Profile.fromJson(res.data as Map<String, dynamic>);
});
