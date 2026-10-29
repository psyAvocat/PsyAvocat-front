import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/user_message.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/widgets/app_alert.dart';
import '../../data/models/messagerie_model.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/theme/universe_provider.dart';
import '../../data/repositories/messagerie_repository.dart';
import '../controllers/conversations_providers.dart';
import '../widgets/avatar_presence.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_input_bar.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/widgets/app_back_button.dart';

/// Discussion avec un professionnel — maquettes « Conversation avocat » et
/// « Conversation psy » : en-tête avec photo, bulles grises (professionnel)
/// et bulles à la couleur de l'univers (client), saisie arrondie.
///
/// Écran unique de discussion, quel que soit le chemin d'accès (messagerie,
/// fiche du professionnel, notification, lien) : le correspondant (nom, métier,
/// photo, présence) est relu depuis la conversation elle-même. Les informations
/// passées à l'ouverture ne servent qu'en attendant, ou pour un brouillon.
///
/// Sans [conversationId], c'est un brouillon avec [destinataireId] (bouton
/// « Écrire » d'une fiche) : rien n'existe côté serveur tant que le premier
/// message n'est pas envoyé, et rien ne reste si l'on repart sans écrire.
class ConversationDetailScreen extends ConsumerStatefulWidget {
  final String? conversationId;
  final String? destinataireId;
  final String? participantName;
  final String? participantRole;
  final String? participantPhotoUrl;

  const ConversationDetailScreen({
    super.key,
    this.conversationId,
    this.destinataireId,
    this.participantName,
    this.participantRole,
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

  /// Null tant que la discussion n'est pas créée (brouillon).
  late String? _conversationId = widget.conversationId;
  late String? _destinataireId = widget.destinataireId;

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

    final repository = ref.read(messagerieRepositoryProvider);
    try {
      final id = _conversationId;
      if (id == null) {
        // Premier message : la discussion est créée (ou reprise) avec lui.
        final conversation = await repository.contacter(
          professionnelId: _destinataireId!,
          message: text,
        );
        if (!mounted) return;
        setState(() => _conversationId = conversation.id);
        ref.invalidate(conversationsProvider);
      } else {
        final message = await repository.envoyer(
          conversationId: id,
          contenu: text,
        );
        if (!mounted) return;
        ref.read(messagesProvider(id).notifier).ajouter(message);
      }
    } catch (error) {
      // Message non envoyé : il revient dans le champ au lieu d'être perdu.
      if (mounted) {
        _textController.text = text;
        AppNotification.showError(context, userMessageFor(error));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  /// Appui long sur l'un de ses messages : suppression pour les deux participants.
  Future<void> _supprimerMessage(Message message) async {
    final id = _conversationId;
    if (id == null) return;
    // Dernier message : le serveur efface la discussion vide, l'écran redevient
    // un brouillon avec le même correspondant.
    final dernier = (ref.read(messagesProvider(id)).value?.length ?? 0) <= 1;
    final correspondant = _destinataireId ?? _correspondantDe(id);
    final confirme = await _confirmer(
      titre: tr('Supprimer ce message ?'),
      texte: tr(
        'Le message sera supprimé pour vous et pour votre correspondant.',
      ),
    );
    if (!confirme || !mounted) return;
    try {
      await ref
          .read(messagerieRepositoryProvider)
          .supprimerMessage(conversationId: id, messageId: message.id);
      if (!mounted) return;
      ref.invalidate(conversationsProvider);
      if (!dernier) {
        ref.read(messagesProvider(id).notifier).retirer(message.id);
      } else if (correspondant != null) {
        setState(() {
          _conversationId = null;
          _destinataireId = correspondant;
        });
      } else {
        Navigator.of(context).maybePop();
      }
    } catch (error) {
      if (mounted) AppNotification.showError(context, userMessageFor(error));
    }
  }

  String? _correspondantDe(String conversationId) => ref
      .read(conversationParIdProvider(conversationId))
      .value
      ?.correspondantId;

  /// Supprime la discussion de sa messagerie ; le professionnel la conserve.
  Future<void> _supprimerConversation() async {
    final id = _conversationId;
    if (id == null) return;
    final confirme = await _confirmer(
      titre: tr('Supprimer cette discussion ?'),
      texte: tr(
        'Elle disparaîtra de votre messagerie. Le professionnel la conserve ; '
        'si l’un de vous écrit à nouveau, elle réapparaîtra avec les nouveaux messages.',
      ),
    );
    if (!confirme || !mounted) return;
    try {
      await ref.read(messagerieRepositoryProvider).supprimerConversation(id);
      ref.invalidate(conversationsProvider);
      if (mounted) Navigator.of(context).maybePop();
    } catch (error) {
      if (mounted) AppNotification.showError(context, userMessageFor(error));
    }
  }

  Future<bool> _confirmer({
    required String titre,
    required String texte,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titre),
        content: Text(texte),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr('Annuler')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr('Supprimer')),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final id = _conversationId;
    final messagesAsync = id == null
        ? const AsyncData<List<Message>>([])
        : ref.watch(messagesProvider(id));
    final currentUserId = ref.watch(authRepositoryProvider).currentUser?.uid;
    final conversation = id == null
        ? null
        : ref.watch(conversationParIdProvider(id)).value;
    final nomConversation = conversation?.correspondantDisplayName ?? '';
    final nom = nomConversation.isNotEmpty
        ? nomConversation
        : widget.participantName ?? tr('Discussion');
    final photo =
        conversation?.correspondantPhotoUrl ?? widget.participantPhotoUrl;
    final role = conversation?.correspondantType ?? widget.participantRole;
    final isAvocat = role != null
        ? role == 'AVOCAT'
        : ref.watch(currentUniverseProvider).isLawyer;
    final correspondantId = conversation?.correspondantId ?? _destinataireId;
    final enLigne =
        correspondantId != null &&
        (ref.watch(presenceProvider)[correspondantId] ?? false);
    // Couleur de l'univers de la discussion (celui du professionnel).
    final couleur = isAvocat ? AppColors.lawyer : AppColors.psychologist;

    return Scaffold(
      backgroundColor: context.palette.card,
      appBar: _EnTete(
        nom: nom,
        role: isAvocat ? 'Avocat' : 'Psychologue',
        photoUrl: photo,
        enLigne: enLigne,
        onSupprimerDiscussion: id == null ? null : _supprimerConversation,
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
                // Fil ancré en bas : le dernier message est toujours visible,
                // et un nouveau message apparaît sans avoir à faire défiler.
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(8, 40, 16, 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[messages.length - 1 - index];
                    return MessageBubble(
                      key: ValueKey(message.id),
                      message: message,
                      primaryColor: couleur,
                      participantName: nom,
                      participantPhotoUrl: photo,
                      currentUserId: currentUserId,
                      onSupprimer: () => _supprimerMessage(message),
                    );
                  },
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

/// En-tête : retour, photo du professionnel (pastille verte s'il est
/// connecté), nom en gras et métier.
class _EnTete extends StatelessWidget implements PreferredSizeWidget {
  final String nom;
  final String role;
  final String? photoUrl;
  final bool enLigne;
  final VoidCallback? onSupprimerDiscussion;

  const _EnTete({
    required this.nom,
    required this.role,
    this.photoUrl,
    this.enLigne = false,
    this.onSupprimerDiscussion,
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
              AvatarPresence(
                name: nom,
                photoUrl: photoUrl,
                size: 52,
                enLigne: enLigne,
              ),
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
                    Text(
                      tr(role),
                      style: AppTypography.texte.copyWith(
                        fontSize: 14,
                        color: context.palette.textStrong,
                      ),
                    ),
                  ],
                ),
              ),
              if (onSupprimerDiscussion != null)
                PopupMenuButton<String>(
                  tooltip: tr('Plus d’actions'),
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: context.palette.textStrong,
                  ),
                  onSelected: (_) => onSupprimerDiscussion!(),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'supprimer',
                      child: ListTile(
                        leading: const Icon(
                          Icons.delete_outline_rounded,
                          color: AppColors.danger,
                        ),
                        title: Text(tr('Supprimer la discussion')),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
