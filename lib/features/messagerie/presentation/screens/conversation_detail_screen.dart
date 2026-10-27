import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../data/repositories/messagerie_repository.dart';
import '../controllers/conversations_providers.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_input_bar.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/widgets/app_back_button.dart';

/// Discussion avec un professionnel — maquettes « Conversation avocat » et
/// « Conversation psy » : en-tête avec photo, bulles grises (professionnel)
/// et bulles à la couleur de l'univers (client), saisie arrondie.
class ConversationDetailScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String participantName;
  final String? participantRole;
  final String? participantPhotoUrl;

  const ConversationDetailScreen({
    super.key,
    required this.conversationId,
    required this.participantName,
    required this.participantRole,
    this.participantPhotoUrl,
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
      ref.invalidate(messagesProvider(widget.conversationId));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesProvider(widget.conversationId));
    final currentUserId = ref.watch(authRepositoryProvider).currentUser?.uid;
    final isAvocat = widget.participantRole == 'AVOCAT';
    // Couleur de l'univers de la discussion (celui du professionnel).
    final couleur = isAvocat ? AppColors.lawyer : AppColors.psychologist;

    return Scaffold(
      backgroundColor: context.palette.card,
      appBar: _EnTete(
        nom: widget.participantName,
        role: isAvocat ? 'Avocat' : 'Psychologue',
        photoUrl: widget.participantPhotoUrl,
        enLigne: ref.watch(correspondantEnLigneProvider(widget.conversationId)),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () =>
                  Center(child: CircularProgressIndicator(color: couleur)),
              error: (err, stack) => Center(
                child: Text(
                  tr('Erreur de chargement'),
                  style: AppTypography.texteSecondaire,
                ),
              ),
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
                            color: couleur.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            tr('Commencez la conversation'),
                            style: AppTypography.texteSemiBold,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            tr(
                              'Posez votre question directement au professionnel.',
                            ),
                            textAlign: TextAlign.center,
                            style: AppTypography.texteSecondaire,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(8, 40, 16, 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) => MessageBubble(
                    message: messages[index],
                    primaryColor: couleur,
                    participantName: widget.participantName,
                    participantPhotoUrl: widget.participantPhotoUrl,
                    currentUserId: currentUserId,
                  ),
                );
              },
            ),
          ),
          ChatInputBar(
            controller: _textController,
            primaryColor: couleur,
            isSending: _isSending,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

/// En-tête : retour, photo du professionnel, nom en gras et métier,
/// suivi de « En ligne » quand le correspondant est connecté.
class _EnTete extends StatelessWidget implements PreferredSizeWidget {
  final String nom;
  final String role;
  final String? photoUrl;
  final bool enLigne;

  const _EnTete({
    required this.nom,
    required this.role,
    this.photoUrl,
    this.enLigne = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(84);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.palette.card,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: preferredSize.height,
          padding: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: context.palette.border)),
          ),
          child: Row(
            children: [
              AppBackButton(color: context.palette.textStrong),
              AppAvatar(name: nom, photoUrl: photoUrl, size: 52),
              AppSpacing.hGap16,
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nom,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.texteSemiBold.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: context.palette.textStrong,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          tr(role),
                          style: AppTypography.texte.copyWith(
                            fontSize: 14,
                            color: context.palette.textStrong,
                          ),
                        ),
                        if (enLigne) ...[
                          const SizedBox(width: 10),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            tr('En ligne'),
                            style: AppTypography.texte.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0E8A63),
                            ),
                          ),
                        ],
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
}
