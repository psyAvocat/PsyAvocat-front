import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/universe_provider.dart';
import '../../data/models/messagerie_model.dart';
import '../../data/repositories/messagerie_repository.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_input_bar.dart';

final _messagesProvider = FutureProvider.family<List<Message>, String>((
  ref,
  convId,
) {
  return ref.read(messagerieRepositoryProvider).getMessages(convId);
});

class ConversationDetailScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String participantName;
  final String? participantRole;

  const ConversationDetailScreen({
    super.key,
    required this.conversationId,
    required this.participantName,
    required this.participantRole,
  });

  @override
  ConsumerState<ConversationDetailScreen> createState() =>
      _ConversationDetailScreenState();
}

class _ConversationDetailScreenState
    extends ConsumerState<ConversationDetailScreen> {
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
      await ref
          .read(messagerieRepositoryProvider)
          .envoyer(conversationId: widget.conversationId, contenu: text);
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
                    ? AppColors.lawyer.withValues(alpha: 0.1)
                    : AppColors.psychologist.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isAvocat ? Icons.gavel_rounded : Icons.psychology_rounded,
                color: isAvocat ? AppColors.lawyer : AppColors.psychologist,
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
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
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
              error: (err, stack) =>
                  const Center(child: Text('Erreur de chargement')),
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.waving_hand_rounded,
                            size: 52,
                            color: primaryColor.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Commencez la conversation',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF374151),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Posez votre question directement au professionnel.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
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
                  itemBuilder: (context, index) => MessageBubble(
                    message: messages[index],
                    primaryColor: primaryColor,
                  ),
                );
              },
            ),
          ),
          ChatInputBar(
            controller: _textController,
            primaryColor: primaryColor,
            isSending: _isSending,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}
