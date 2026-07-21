import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ridebuddy/models/models.dart';
import 'package:ridebuddy/providers/auth_provider.dart';
import 'package:ridebuddy/services/api_client.dart';
import 'package:ridebuddy/services/chat_repository.dart';
import 'package:ridebuddy/services/chat_socket.dart';

final chatInboxProvider = FutureProvider.autoDispose<List<ChatConversation>>((ref) async {
  ref.watch(authStateProvider.select((s) => s.userId));
  ref.watch(chatSocketProvider);
  return ref.read(chatRepositoryProvider).conversations();
});

final chatUnreadTotalProvider = Provider.autoDispose<int>((ref) {
  final inbox = ref.watch(chatInboxProvider).valueOrNull ?? const [];
  return inbox.fold<int>(0, (sum, c) => sum + c.unreadCount);
});

class ChatThreadState {
  const ChatThreadState({
    this.messages = const [],
    this.loading = true,
    this.sending = false,
    this.canSend = true,
    this.error,
    this.conversation,
  });

  final List<ChatMessage> messages;
  final bool loading;
  final bool sending;
  final bool canSend;
  final String? error;
  final ChatConversation? conversation;

  ChatThreadState copyWith({
    List<ChatMessage>? messages,
    bool? loading,
    bool? sending,
    bool? canSend,
    String? error,
    ChatConversation? conversation,
    bool clearError = false,
  }) {
    return ChatThreadState(
      messages: messages ?? this.messages,
      loading: loading ?? this.loading,
      sending: sending ?? this.sending,
      canSend: canSend ?? this.canSend,
      error: clearError ? null : (error ?? this.error),
      conversation: conversation ?? this.conversation,
    );
  }
}

final chatThreadProvider =
    StateNotifierProvider.autoDispose.family<ChatThreadController, ChatThreadState, String>(
  (ref, conversationId) => ChatThreadController(ref, conversationId),
);

class ChatThreadController extends StateNotifier<ChatThreadState> {
  ChatThreadController(this._ref, this.conversationId) : super(const ChatThreadState()) {
    _init();
  }

  final Ref _ref;
  final String conversationId;
  StreamSubscription<ChatMessage>? _socketSub;

  Future<void> _init() async {
    final socket = _ref.read(chatSocketProvider);
    _socketSub = socket.messages.listen((msg) {
      if (msg.conversationId != conversationId) return;
      if (state.messages.any((m) => m.id == msg.id)) return;
      state = state.copyWith(messages: [...state.messages, msg]);
      _ref.invalidate(chatInboxProvider);
    });
    await reload();
  }

  Future<void> reload() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final repo = _ref.read(chatRepositoryProvider);
      final inbox = await repo.conversations();
      ChatConversation? conv;
      for (final c in inbox) {
        if (c.id == conversationId) {
          conv = c;
          break;
        }
      }
      final page = await repo.messages(conversationId);
      final chronological = page.reversed.toList();
      state = state.copyWith(
        messages: chronological,
        loading: false,
        canSend: conv?.canSend ?? true,
        conversation: conv,
      );
      _ref.invalidate(chatInboxProvider);
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: _ref.read(apiClientProvider).messageFrom(e),
      );
    }
  }

  Future<void> send(String body) async {
    final text = body.trim();
    if (text.isEmpty || state.sending) return;
    state = state.copyWith(sending: true, clearError: true);
    try {
      final msg = await _ref.read(chatRepositoryProvider).send(conversationId, text);
      if (!state.messages.any((m) => m.id == msg.id)) {
        state = state.copyWith(messages: [...state.messages, msg], sending: false);
      } else {
        state = state.copyWith(sending: false);
      }
      _ref.invalidate(chatInboxProvider);
    } catch (e) {
      state = state.copyWith(
        sending: false,
        error: _ref.read(apiClientProvider).messageFrom(e),
      );
      rethrow;
    }
  }

  @override
  void dispose() {
    _socketSub?.cancel();
    super.dispose();
  }
}
