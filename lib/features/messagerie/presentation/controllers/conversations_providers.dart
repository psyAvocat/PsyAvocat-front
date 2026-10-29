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
  listenRealtime(ref, {
    RealtimeEventType.message,
    RealtimeEventType.reconnecte,
  }, (_) => ref.invalidateSelf());
  final conversations = await ref
      .read(messagerieRepositoryProvider)
      .getConversations();
  ref.read(presenceProvider.notifier).initialiser(conversations);
  return conversations.where((c) => c.universe == universe).toList();
});

/// Présence des correspondants (identifiant → en ligne) : état lu avec les
/// conversations, puis tenu à jour par les événements temps réel `PRESENCE`.
final presenceProvider = NotifierProvider<PresenceNotifier, Map<String, bool>>(
  PresenceNotifier.new,
);

class PresenceNotifier extends Notifier<Map<String, bool>> {
  @override
  Map<String, bool> build() {
    listenRealtime(ref, {RealtimeEventType.presence}, (event) {
      final id = event.payload['utilisateurId'];
      if (id is String) {
        state = {...state, id: event.payload['enLigne'] == true};
      }
    });
    return const {};
  }

  void initialiser(List<Conversation> conversations) {
    state = {
      ...state,
      for (final c in conversations)
        if (c.correspondantId != null)
          c.correspondantId!: c.correspondantEnLigne,
    };
  }
}

/// Conversation ouverte, quel que soit le chemin d'accès (liste, fiche du
/// professionnel, notification ou lien) et quel que soit l'univers courant :
/// l'écran de discussion en tire le nom, le métier, la photo et la présence du
/// correspondant, pour un affichage identique dans tous les cas.
final conversationParIdProvider = FutureProvider.autoDispose
    .family<Conversation?, String>((ref, id) async {
      final conversations = await ref
          .read(messagerieRepositoryProvider)
          .getConversations();
      ref.read(presenceProvider.notifier).initialiser(conversations);
      for (final c in conversations) {
        if (c.id == id) return c;
      }
      return null;
    });

/// Messages d'une conversation, du plus ancien au plus récent, chacun une seule fois.
///
/// - message envoyé : ajouté dès la réponse du serveur ([MessagesNotifier.ajouter]) ;
/// - message reçu en temps réel : affiché aussitôt, puis la conversation est
///   relue (le serveur le marque lu, la cloche et la liste se mettent à jour) ;
/// - message supprimé : retiré ;
/// - reconnexion après une coupure : relue (événements manqués).
final messagesProvider = AsyncNotifierProvider.autoDispose
    .family<MessagesNotifier, List<Message>, String>(MessagesNotifier.new);

class MessagesNotifier extends AsyncNotifier<List<Message>> {
  MessagesNotifier(this.conversationId);

  final String conversationId;

  /// Messages ajoutés localement (envoyés ou reçus en temps réel), avec l'instant
  /// de l'ajout : une relecture partie avant cet instant ne les connaît pas
  /// encore et ne doit pas les faire disparaître.
  final _ajoutsLocaux = <String, DateTime>{};

  @override
  Future<List<Message>> build() async {
    listenRealtime(ref, {
      RealtimeEventType.message,
      RealtimeEventType.reconnecte,
    }, _surEvenement);
    final debut = DateTime.now();
    final serveur = await ref
        .read(messagerieRepositoryProvider)
        .getMessages(conversationId);
    final connus = {for (final m in serveur) m.id};
    final ajoutesPendantLaLecture = (state.value ?? const <Message>[]).where(
      (m) =>
          !connus.contains(m.id) &&
          (_ajoutsLocaux[m.id]?.isAfter(debut) ?? false),
    );
    _ajoutsLocaux.removeWhere((id, _) => connus.contains(id));
    ref.invalidate(conversationsProvider);
    ref.read(notificationsControllerProvider.notifier).refresh();
    return filDeMessages([...serveur, ...ajoutesPendantLaLecture]);
  }

  void _surEvenement(RealtimeEvent event) {
    if (event.type == RealtimeEventType.reconnecte) {
      ref.invalidateSelf();
      return;
    }
    final evenement = event.payload;
    if (evenement['conversationId']?.toString() != conversationId ||
        evenement['conversationSupprimee'] == true) {
      return;
    }
    if (evenement['supprime'] == true) {
      retirer('${evenement['id']}');
    } else if (evenement['id'] != null) {
      ajouter(Message.fromJson(evenement));
    }
    ref.invalidateSelf();
  }

  /// Message confirmé par le serveur : affiché une seule fois.
  void ajouter(Message message) {
    _ajoutsLocaux[message.id] = DateTime.now();
    final actuels = state.value;
    if (actuels != null) {
      state = AsyncData(filDeMessages([...actuels, message]));
    }
  }

  void retirer(String id) {
    _ajoutsLocaux.remove(id);
    final actuels = state.value;
    if (actuels != null) {
      state = AsyncData(actuels.where((m) => m.id != id).toList());
    }
  }
}
