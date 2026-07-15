import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ridebuddy/config/env.dart';

final secureStorageProvider = Provider((_) => const FlutterSecureStorage());

/// Fired when access + refresh tokens are invalid — listeners should clear AuthState.
final authSessionExpiredProvider = StateProvider<int>((ref) => 0);

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref);
});

class ApiClient {
  ApiClient(this._ref) {
    _dio = Dio(BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _ref.read(secureStorageProvider).read(key: 'access_token');
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final code = error.response?.statusCode;
        // Spring often returns 403 for anonymous/expired JWT when entry point isn't set.
        if (code == 401 || code == 403) {
          final path = error.requestOptions.path;
          if (path.contains('/auth/')) {
            return handler.next(error);
          }
          final refreshed = await _tryRefresh();
          if (refreshed) {
            final req = error.requestOptions;
            final token = await _ref.read(secureStorageProvider).read(key: 'access_token');
            req.headers['Authorization'] = 'Bearer $token';
            try {
              final clone = await _dio.fetch(req);
              return handler.resolve(clone);
            } catch (e) {
              if (e is DioException) return handler.next(e);
              return handler.next(error);
            }
          }
          _ref.read(authSessionExpiredProvider.notifier).state++;
        }
        handler.next(error);
      },
    ));
  }

  final Ref _ref;
  late final Dio _dio;
  bool _refreshing = false;

  Dio get dio => _dio;

  Future<bool> _tryRefresh() async {
    if (_refreshing) return false;
    _refreshing = true;
    try {
      final storage = _ref.read(secureStorageProvider);
      final refresh = await storage.read(key: 'refresh_token');
      if (refresh == null || refresh.isEmpty) return false;
      final res = await Dio(BaseOptions(baseUrl: Env.apiBaseUrl)).post(
        '/auth/refresh',
        data: {'refreshToken': refresh},
      );
      final data = res.data as Map<String, dynamic>;
      await storage.write(key: 'access_token', value: data['accessToken'] as String);
      await storage.write(key: 'refresh_token', value: data['refreshToken'] as String);
      return true;
    } catch (_) {
      await _ref.read(secureStorageProvider).deleteAll();
      return false;
    } finally {
      _refreshing = false;
    }
  }

  String messageFrom(Object e) {
    if (e is DioException) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return 'Could not reach the server at ${Env.apiBaseUrl}. '
            'Check that the backend is running and API_BASE_URL in .env uses your '
            'computer\'s LAN IP (not the router). Phone and computer must be on the same Wi‑Fi.';
      }
      if (e.type == DioExceptionType.connectionError) {
        return 'Connection failed (${Env.apiBaseUrl}). '
            'Start the backend (./run-local.sh) and confirm the IP in .env.';
      }
      final code = e.response?.statusCode;
      if (code == 401 || code == 403) {
        return 'Session expired — please sign in again';
      }
      final data = e.response?.data;
      if (data is Map) {
        if (data['detail'] != null) return data['detail'].toString();
        if (data['title'] != null && data['title'] != 'Bad Request') return data['title'].toString();
        if (data['message'] != null) return data['message'].toString();
      }
      return e.message ?? 'Network error';
    }
    return e.toString();
  }
}
