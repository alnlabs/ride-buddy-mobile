import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ridebuddy/config/env.dart';
import 'package:ridebuddy/models/models.dart';
import 'package:ridebuddy/providers/auth_provider.dart';
import 'package:ridebuddy/services/api_client.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

final chatSocketProvider = Provider<ChatSocket>((ref) {
  final socket = ChatSocket(ref);
  ref.onDispose(socket.dispose);
  ref.listen<AuthState>(authStateProvider, (prev, next) {
    if (next.isAuthenticated) {
      socket.connect();
    } else {
      socket.disconnect();
    }
  });
  if (ref.read(authStateProvider).isAuthenticated) {
    Future.microtask(socket.connect);
  }
  return socket;
});

/// Broadcasts realtime chat messages for the signed-in user.
class ChatSocket {
  ChatSocket(this._ref);

  final Ref _ref;
  StompClient? _client;
  final _controller = StreamController<ChatMessage>.broadcast();
  bool _connecting = false;

  Stream<ChatMessage> get messages => _controller.stream;

  Future<void> connect() async {
    if (_connecting) return;
    final token = await _ref.read(secureStorageProvider).read(key: 'access_token');
    if (token == null || token.isEmpty) return;
    if (_client?.connected == true) return;

    _connecting = true;
    try {
      await disconnect();
      final url = Env.wsNativeUrl(accessToken: token);
      final client = StompClient(
        config: StompConfig(
          url: url,
          onConnect: (frame) {
            _client?.subscribe(
              destination: '/user/queue/chat',
              callback: (frame) {
                final body = frame.body;
                if (body == null || body.isEmpty) return;
                try {
                  final map = jsonDecode(body) as Map<String, dynamic>;
                  if (!_controller.isClosed) {
                    _controller.add(ChatMessage.fromJson(map));
                  }
                } catch (_) {}
              },
            );
          },
          onWebSocketError: (_) {
            // Reconnect is handled by stomp_dart_client when reconnectDelay is set.
          },
          reconnectDelay: const Duration(seconds: 4),
          connectionTimeout: const Duration(seconds: 12),
        ),
      );
      _client = client;
      client.activate();
    } finally {
      _connecting = false;
    }
  }

  Future<void> disconnect() async {
    final c = _client;
    _client = null;
    try {
      c?.deactivate();
    } catch (_) {}
  }

  void dispose() {
    disconnect();
    _controller.close();
  }
}
