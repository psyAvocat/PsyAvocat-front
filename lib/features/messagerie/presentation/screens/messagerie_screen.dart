import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/universe_provider.dart';
import '../../data/models/messagerie_model.dart';
import '../../data/repositories/messagerie_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Provider pour la liste des conversations
// ─────────────────────────────────────────────────────────────────────────────
final conversationsProvider = FutureProvider.autoDispose<List<ConversationModel>>((ref) {
  return ref.read(messagerieRepositoryProvider).getMesConversations();
});

/// Écran Messagerie — liste des conversations avec les professionnels.
/// Connecté à GET /api/conversations via ApiMessagerieRepository.
class MessagerieScreen extends ConsumerWidget {
  const MessagerieScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final universe = ref.watch(currentUniverseProvider);
    final primaryColor = universe.primaryColor;
    final conversationsAsync = ref.watch(conversationsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Messages',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
            fontFamily: 'Montserrat',
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search_rounded, color: primaryColor),
            onPressed: () {},
            tooltip: 'Rechercher',
          ),
        ],
      ),
      body: SafeArea(
        child: conversationsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorState(onRetry: () => ref.invalidate(conversationsProvider)),
          data: (conversations) {
            if (conversations.isEmpty) {
              return _EmptyState(primaryColor: primaryColor);
            }
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(conversationsProvider),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                itemCount: conversations.length,
                itemBuilder: (context, index) {
                  return _ConversationCard(
                    conversation: conversations[index],
                    primaryColor: primaryColor,
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

// ─── Widget carte conversation ────────────────────────────────────────────────
class _ConversationCard extends StatelessWidget {
  final ConversationModel conversation;
  final Color primaryColor;

  const _ConversationCard({required this.conversation, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    final hasUnread = conversation.messagesNonLus > 0;
    final isAvocat = conversation.participantRole == 'AVOCAT';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: hasUnread
            ? Border.all(color: primaryColor.withValues(alpha: 0.3), width: 1.5)
            : Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ConversationDetailScreen(
                conversationId: conversation.id,
                participantName: conversation.displayName,
                participantRole: conversation.participantRole,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isAvocat
                      ? const Color(0xFF1B2A5A).withValues(alpha: 0.1)
                      : const Color(0xFF7C3AED).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isAvocat ? Icons.gavel_rounded : Icons.psychology_rounded,
                  color: isAvocat ? const Color(0xFF1B2A5A) : const Color(0xFF7C3AED),
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              // Contenu
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.displayName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: hasUnread ? FontWeight.w800 : FontWeight.w600,
                              color: const Color(0xFF111827),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (conversation.dernierMessageDate != null)
                          Text(
                            _formatDate(conversation.dernierMessageDate!),
                            style: TextStyle(
                              fontSize: 12,
                              color: hasUnread ? primaryColor : const Color(0xFF9CA3AF),
                              fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w400,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.dernierMessage ?? 'Aucun message',
                            style: TextStyle(
                              fontSize: 13,
                              color: hasUnread ? const Color(0xFF374151) : const Color(0xFF9CA3AF),
                              fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasUnread)
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              conversation.messagesNonLus.toString(),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}min';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}j';
    return '${date.day}/${date.month}';
  }
}

// ─── État vide ─────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final Color primaryColor;
  const _EmptyState({required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 72,
              color: primaryColor.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 20),
            const Text(
              'Aucune conversation',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E2432),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Vos conversations avec les avocats et psychologues apparaîtront ici.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── État erreur ─────────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 60, color: Color(0xFFD1D5DB)),
          const SizedBox(height: 16),
          const Text('Impossible de charger les messages'),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Écran détail conversation (chat)
// ─────────────────────────────────────────────────────────────────────────────

final _messagesProvider = FutureProvider.family<List<MessageModel>, String>((ref, convId) {
  return ref.read(messagerieRepositoryProvider).getMessages(convId, '');
});

class ConversationDetailScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String participantName;
  final String participantRole;

  const ConversationDetailScreen({
    super.key,
    required this.conversationId,
    required this.participantName,
    required this.participantRole,
  });

  @override
  ConsumerState<ConversationDetailScreen> createState() => _ConversationDetailScreenState();
}

class _ConversationDetailScreenState extends ConsumerState<ConversationDetailScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _textController.clear();

    try {
      await ref.read(messagerieRepositoryProvider).sendMessage(widget.conversationId, text);
      ref.invalidate(_messagesProvider(widget.conversationId));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final universe = ref.watch(currentUniverseProvider);
    final primaryColor = universe.primaryColor;
    final messagesAsync = ref.watch(_messagesProvider(widget.conversationId));
    final isAvocat = widget.participantRole == 'AVOCAT';

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isAvocat
                    ? const Color(0xFF1B2A5A).withValues(alpha: 0.1)
                    : const Color(0xFF7C3AED).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isAvocat ? Icons.gavel_rounded : Icons.psychology_rounded,
                color: isAvocat ? const Color(0xFF1B2A5A) : const Color(0xFF7C3AED),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.participantName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    isAvocat ? 'Avocat' : 'Psychologue',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => const Center(child: Text('Erreur de chargement')),
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.waving_hand_rounded, size: 52, color: primaryColor.withValues(alpha: 0.4)),
                          const SizedBox(height: 16),
                          const Text(
                            'Commencez la conversation',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Posez votre question directement au professionnel.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) => _MessageBubble(
                    message: messages[index],
                    primaryColor: primaryColor,
                  ),
                );
              },
            ),
          ),
          // Barre de saisie
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Color(0x10000000), blurRadius: 10, offset: Offset(0, -3)),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: 'Votre message...',
                        hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                        filled: true,
                        fillColor: const Color(0xFFF3F4F6),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: _isSending ? null : _send,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: _isSending
                          ? const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              ),
                            )
                          : const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final Color primaryColor;

  const _MessageBubble({required this.message, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    final isMe = message.isFromMe;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe ? primaryColor : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          message.contenu,
          style: TextStyle(
            fontSize: 14,
            color: isMe ? Colors.white : const Color(0xFF1E2432),
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
