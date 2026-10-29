import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_providers.dart';
import '../models/messagerie_model.dart';

/// Messagerie client ↔ professionnel (Spring Boot `/api/conversations`).
abstract class MessagerieRepository {
  Future<List<Conversation>> getConversations();

  /// Total des messages non lus, tous univers confondus.
  Future<int> getUnreadCount();

  /// Messages d'une conversation (le backend les marque lus pour l'appelant).
  Future<List<Message>> getMessages(String conversationId);

  Future<Message> envoyer({
    required String conversationId,
    required String contenu,
  });

  /// Discussion à ouvrir avec un professionnel (bouton « Écrire ») : l'existante,
  /// ou un brouillon (`id` vide) qui n'existe qu'à l'écran. Rien n'est créé :
  /// la discussion naît avec le premier message ([contacter]).
  Future<Conversation> ouvrirAvec(String destinataireId);

  /// Contacte un professionnel : réutilise la conversation existante si elle existe.
  Future<Conversation> contacter({
    required String professionnelId,
    required String message,
  });

  /// Supprime l'un de ses messages, pour les deux participants.
  Future<void> supprimerMessage({
    required String conversationId,
    required String messageId,
  });

  /// Supprime la discussion de sa messagerie (le professionnel la conserve).
  Future<void> supprimerConversation(String conversationId);
}

class ApiMessagerieRepository implements MessagerieRepository {
  final ApiClient _client;

  ApiMessagerieRepository(this._client);

  @override
  Future<List<Conversation>> getConversations() async {
    final response = await _client.get('/conversations');
    final list = response.data as List<dynamic>? ?? [];
    return list
        .map((e) => Conversation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<int> getUnreadCount() async {
    final response = await _client.get('/conversations/unread-count');
    final data = response.data;
    if (data is Map<String, dynamic>)
      return (data['unreadCount'] as num?)?.toInt() ?? 0;
    return 0;
  }

  @override
  Future<List<Message>> getMessages(String conversationId) async {
    final response = await _client.get(
      '/conversations/$conversationId/messages',
    );
    final list = response.data as List<dynamic>? ?? [];
    return list
        .map((e) => Message.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Message> envoyer({
    required String conversationId,
    required String contenu,
  }) async {
    final response = await _client.post(
      '/conversations/$conversationId/messages',
      data: {'contenu': contenu},
    );
    return Message.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<Conversation> ouvrirAvec(String destinataireId) async {
    final response = await _client.get('/conversations/avec/$destinataireId');
    return Conversation.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<Conversation> contacter({
    required String professionnelId,
    required String message,
  }) async {
    final response = await _client.post(
      '/conversations',
      data: {'destinataireId': professionnelId, 'premierMessage': message},
    );
    return Conversation.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> supprimerMessage({
    required String conversationId,
    required String messageId,
  }) async {
    await _client.delete('/conversations/$conversationId/messages/$messageId');
  }

  @override
  Future<void> supprimerConversation(String conversationId) async {
    await _client.delete('/conversations/$conversationId');
  }
}

final messagerieRepositoryProvider = Provider<MessagerieRepository>((ref) {
  return ApiMessagerieRepository(ref.watch(apiClientProvider));
});
