import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/realtime/realtime_service.dart';
import '../../../../core/theme/universe_provider.dart';
import '../../../notifications/presentation/controllers/notifications_controller.dart';
import '../../data/models/messagerie_model.dart';
import '../../data/repositories/messagerie_repository.dart';

/// Conversations de l'univers courant uniquement (cloisonnement Avocat / Psychologue),
/// rechargées à chaque nouveau message reçu en temps réel.
final conversationsProvider = FutureProvider.autoDispose<List<Conversation>>((
  ref,
) async {
  final universe = ref.watch(currentUniverseProvider);
  listenRealtime(ref, {RealtimeEventType.message}, (_) => ref.invalidateSelf());
  final conversations = await ref
      .read(messagerieRepositoryProvider)
      .getConversations();
  return conversations.where((c) => c.universe == universe).toList();
});

/// Messages d'une conversation, relus à chaque ouverture et à chaque nouveau
/// message de cette conversation.
///
/// La lecture marque côté serveur les messages reçus (et leurs notifications
/// « Nouveau message ») comme lus : la liste des conversations et la cloche sont
/// alors rechargées pour que les compteurs ne restent pas figés.
final messagesProvider = FutureProvider.autoDispose
    .family<List<Message>, String>((ref, conversationId) async {
      listenRealtime(ref, {RealtimeEventType.message}, (event) {
        if (event.payload['conversationId'] == conversationId) {
          ref.invalidateSelf();
        }
      });
      final messages = await ref
          .read(messagerieRepositoryProvider)
          .getMessages(conversationId);
      ref.invalidate(conversationsProvider);
      ref.read(notificationsControllerProvider.notifier).refresh();
      return messages;
    });
