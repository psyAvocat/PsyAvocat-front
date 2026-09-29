import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/messagerie_model.dart';
import '../../data/repositories/messagerie_repository.dart';

/// Provider des conversations de l'utilisateur connecté
final conversationsListProvider =
    AsyncNotifierProvider<ConversationsNotifier, List<ConversationModel>>(
  ConversationsNotifier.new,
);

class ConversationsNotifier extends AsyncNotifier<List<ConversationModel>> {
  @override
  Future<List<ConversationModel>> build() async {
    return ref.read(messagerieRepositoryProvider).getMesConversations();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(messagerieRepositoryProvider).getMesConversations(),
    );
  }
}

/// Provider des messages d'une conversation donnée (paramétré par conversationId et myUid)
final messagesListProvider = FutureProvider.family<List<MessageModel>, ({String conversationId, String myUid})>(
  (ref, params) async {
    return ref
        .read(messagerieRepositoryProvider)
        .getMessages(params.conversationId, params.myUid);
  },
);
