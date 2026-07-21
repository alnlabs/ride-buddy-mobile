import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ridebuddy/models/models.dart';
import 'package:ridebuddy/services/api_client.dart';

final chatRepositoryProvider = Provider((ref) => ChatRepository(ref));

class ChatRepository {
  ChatRepository(this._ref);

  final Ref _ref;

  ApiClient get _api => _ref.read(apiClientProvider);

  Future<List<ChatConversation>> conversations() async {
    final res = await _api.dio.get('/chat/conversations');
    final list = res.data as List<dynamic>? ?? [];
    return list.map((e) => ChatConversation.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ChatConversation> open({
    String? bookingId,
    String? offerId,
    String? rideId,
    String? coRiderId,
  }) async {
    final res = await _api.dio.post('/chat/conversations/open', data: {
      if (bookingId != null) 'bookingId': bookingId,
      if (offerId != null) 'offerId': offerId,
      if (rideId != null) 'rideId': rideId,
      if (coRiderId != null) 'coRiderId': coRiderId,
    });
    return ChatConversation.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<ChatMessage>> messages(String conversationId, {DateTime? before, int limit = 50}) async {
    final res = await _api.dio.get(
      '/chat/conversations/$conversationId/messages',
      queryParameters: {
        'limit': limit,
        if (before != null) 'before': before.toUtc().toIso8601String(),
      },
    );
    final list = res.data as List<dynamic>? ?? [];
    return list.map((e) => ChatMessage.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ChatMessage> send(String conversationId, String body) async {
    final res = await _api.dio.post(
      '/chat/conversations/$conversationId/messages',
      data: {'body': body},
    );
    return ChatMessage.fromJson(res.data as Map<String, dynamic>);
  }
}
