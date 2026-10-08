import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/realtime/realtime_service.dart';
import '../../../../core/theme/universe_provider.dart';
import '../../data/models/messagerie_model.dart';
import '../../data/repositories/messagerie_repository.dart';

/// Conversations du compte, rechargées à chaque message reçu ou envoyé.
class ConversationsController extends AsyncNotifier<List<Conversation>> {
  @override
  Future<List<Conversation>> build() {
    listenRealtime(ref, {RealtimeEventType.message}, (_) => reload());
    return ref.read(messagerieRepositoryProvider).getConversations();
  }

  Future<void> reload() async {
    final result = await AsyncValue.guard(
      () => ref.read(messagerieRepositoryProvider).getConversations(),
    );
    if (result.hasValue || !state.hasValue) state = result;
  }

  /// Contacte un professionnel (réutilise la conversation existante).
  Future<Conversation> contacter({
    required String professionnelId,
    required String message,
  }) async {
    final conversation = await ref
        .read(messagerieRepositoryProvider)
        .contacter(professionnelId: professionnelId, message: message);
    await reload();
    return conversation;
  }
}

final conversationsControllerProvider =
    AsyncNotifierProvider<ConversationsController, List<Conversation>>(
      ConversationsController.new,
    );

/// Conversations de l'univers courant uniquement (jamais de mélange).
final visibleConversationsProvider = Provider<AsyncValue<List<Conversation>>>((ref) {
  final universe = ref.watch(currentUniverseProvider);
  return ref.watch(conversationsControllerProvider).whenData((items) {
    final visible = items.where((c) => c.universe == universe).toList()
      ..sort((a, b) {
        final da = a.dernierMessage?.dateEnvoi ?? DateTime(0);
        final db = b.dernierMessage?.dateEnvoi ?? DateTime(0);
        return db.compareTo(da);
      });
    return visible;
  });
});

/// Badge de la messagerie : messages non lus de l'univers courant.
final unreadMessagesBadgeProvider = Provider<int>((ref) {
  final items = ref.watch(visibleConversationsProvider).value ?? const [];
  return items.fold(0, (total, c) => total + c.messagesNonLus);
});

/// Fil d'une conversation : chargement, envoi, réception en temps réel.
class ConversationThreadController extends AsyncNotifier<List<Message>> {
  final String conversationId;

  ConversationThreadController(this.conversationId);

  @override
  Future<List<Message>> build() async {
    listenRealtime(ref, {RealtimeEventType.message}, (event) {
      final message = Message.fromJson(event.payload);
      if (message.conversationId == conversationId) {
        _append(message);
        // Fil ouvert : relire depuis le serveur marque le message comme lu.
        _syncRead();
      }
    });
    final messages = await ref.read(messagerieRepositoryProvider).getMessages(conversationId);
    // Les messages viennent d'être lus côté serveur : on met à jour les badges.
    Future.microtask(() => ref.read(conversationsControllerProvider.notifier).reload());
    return _sorted(messages);
  }

  Future<void> _syncRead() async {
    try {
      final messages = await ref.read(messagerieRepositoryProvider).getMessages(conversationId);
      state = AsyncData(_sorted(messages));
      await ref.read(conversationsControllerProvider.notifier).reload();
    } catch (_) {
      // Le fil affiché reste valide ; la lecture sera synchronisée au prochain chargement.
    }
  }

  Future<void> envoyer(String contenu) async {
    final texte = contenu.trim();
    if (texte.isEmpty) return;
    final message = await ref
        .read(messagerieRepositoryProvider)
        .envoyer(conversationId: conversationId, contenu: texte);
    _append(message);
  }

  void _append(Message message) {
    final current = state.value;
    if (current == null) return;
    // Le message envoyé revient aussi par WebSocket : pas de doublon.
    if (current.any((m) => m.id == message.id)) return;
    state = AsyncData(_sorted([...current, message]));
  }

  static List<Message> _sorted(List<Message> messages) => [...messages]
    ..sort((a, b) => (a.dateEnvoi ?? DateTime(0)).compareTo(b.dateEnvoi ?? DateTime(0)));
}

/// autoDispose : une fois l'écran quitté, les messages reçus ne sont plus marqués lus.
final conversationThreadProvider =
    AsyncNotifierProvider.autoDispose.family<ConversationThreadController, List<Message>, String>(
      ConversationThreadController.new,
    );
