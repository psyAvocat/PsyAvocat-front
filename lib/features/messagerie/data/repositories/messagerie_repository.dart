import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_providers.dart';
import '../models/messagerie_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Repository Messagerie — Interface abstraite & Implémentation API
// ─────────────────────────────────────────────────────────────────────────────

abstract class MessagerieRepository {
  Future<List<ConversationModel>> getMesConversations();
  Future<List<MessageModel>> getMessages(String conversationId, String myUid);
  Future<ConversationModel> createConversation(String professionnelId);
  Future<MessageModel> sendMessage(String conversationId, String contenu);
}

class ApiMessagerieRepository implements MessagerieRepository {
  final ApiClient _client;

  ApiMessagerieRepository(this._client);

  @override
  Future<List<ConversationModel>> getMesConversations() async {
    try {
      final response = await _client.get('/conversations');
      final list = response.data as List<dynamic>? ?? [];
      return list
          .map((e) => ConversationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<MessageModel>> getMessages(String conversationId, String myUid) async {
    try {
      final response = await _client.get('/conversations/$conversationId/messages');
      final list = response.data as List<dynamic>? ?? [];
      return list
          .map((e) => MessageModel.fromJson(e as Map<String, dynamic>, myUid))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<ConversationModel> createConversation(String professionnelId) async {
    final response = await _client.post('/conversations', data: {
      'professionnelId': professionnelId,
    });
    return ConversationModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<MessageModel> sendMessage(String conversationId, String contenu) async {
    final response = await _client.post(
      '/conversations/$conversationId/messages',
      data: {'contenu': contenu},
    );
    return MessageModel.fromJson(response.data as Map<String, dynamic>, '');
  }
}

final messagerieRepositoryProvider = Provider<MessagerieRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return ApiMessagerieRepository(client);
});
