import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/realtime/realtime_service.dart';
import '../../../../core/theme/universe_provider.dart';
import '../../data/models/messagerie_model.dart';
import '../../data/repositories/messagerie_repository.dart';
import '../widgets/conversation_card.dart';
import '../widgets/messagerie_empty_state.dart';
import '../widgets/messagerie_error_state.dart';
import 'conversation_detail_screen.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/design_system.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Provider pour la liste des conversations
// ─────────────────────────────────────────────────────────────────────────────
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

/// Écran Messagerie — liste des conversations avec les professionnels.
/// Connecté à GET /api/conversations via ApiMessagerieRepository.
class MessagerieScreen extends ConsumerWidget {
  const MessagerieScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final conversationsAsync = ref.watch(conversationsProvider);

    return Scaffold(
      backgroundColor: context.palette.page,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Text(
          tr('Messages'),
          style: AppTypography.titreMoyen.copyWith(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: context.palette.textStrong,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search_rounded, color: primaryColor),
            onPressed: () {},
            tooltip: tr('Rechercher'),
          ),
        ],
      ),
      body: SafeArea(
        child: conversationsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => MessagerieErrorState(
            onRetry: () => ref.invalidate(conversationsProvider),
          ),
          data: (conversations) {
            if (conversations.isEmpty) {
              return MessagerieEmptyState(primaryColor: primaryColor);
            }
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(conversationsProvider),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                itemCount: conversations.length,
                itemBuilder: (context, index) {
                  final conversation = conversations[index];
                  return ConversationCard(
                    conversation: conversation,
                    primaryColor: primaryColor,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ConversationDetailScreen(
                            conversationId: conversation.id,
                            participantName:
                                conversation.correspondantDisplayName,
                            participantRole: conversation.correspondantType,
                            participantPhotoUrl:
                                conversation.correspondantPhotoUrl,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
