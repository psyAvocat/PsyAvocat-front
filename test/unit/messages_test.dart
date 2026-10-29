import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psyavocat_front/core/realtime/realtime_service.dart';
import 'package:psyavocat_front/features/messagerie/data/models/messagerie_model.dart';
import 'package:psyavocat_front/features/messagerie/data/repositories/messagerie_repository.dart';
import 'package:psyavocat_front/features/messagerie/presentation/controllers/conversations_providers.dart';
import 'package:psyavocat_front/features/notifications/data/models/notification_model.dart';
import 'package:psyavocat_front/features/notifications/presentation/controllers/notifications_controller.dart';

class _SansNotifications extends NotificationsController {
  @override
  Future<List<NotificationItem>> build() async => const [];

  @override
  Future<void> refresh() async {}
}

/// Serveur simulé : la conversation « c1 » contient [serveur].
class _FausseMessagerie extends Fake implements MessagerieRepository {
  final serveur = <Map<String, dynamic>>[];

  /// Lecture en attente (pour simuler une réponse lente).
  Completer<void>? attente;

  @override
  Future<List<Conversation>> getConversations() async => const [];

  @override
  Future<List<Message>> getMessages(String conversationId) async {
    if (attente != null) await attente!.future;
    return serveur.map(Message.fromJson).toList();
  }
}

Map<String, dynamic> _json(String id, String date) => {
  'id': id,
  'conversationId': 'c1',
  'contenu': 'Contenu $id',
  'dateEnvoi': date,
  'expediteurId': 'pro-1',
  'lu': false,
};

Future<void> _attendre() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  test(
    'fil : chaque message une seule fois, du plus ancien au plus récent',
    () {
      final m1 = Message.fromJson(_json('m1', '2026-10-28T10:00:00'));
      final m2 = Message.fromJson(_json('m2', '2026-10-28T10:00:00.500001'));

      expect(filDeMessages([m2, m1, m2]).map((m) => m.id), ['m1', 'm2']);
    },
  );

  group('Messages d’une conversation', () {
    late StreamController<RealtimeEvent> evenements;
    late _FausseMessagerie messagerie;
    late ProviderContainer container;

    List<String> affiches() =>
        container.read(messagesProvider('c1')).value!.map((m) => m.id).toList();

    setUp(() async {
      evenements = StreamController<RealtimeEvent>.broadcast();
      messagerie = _FausseMessagerie()
        ..serveur.add(_json('m1', '2026-10-28T10:00:00'));
      container = ProviderContainer(
        overrides: [
          realtimeEventsProvider.overrideWith((ref) => evenements.stream),
          messagerieRepositoryProvider.overrideWithValue(messagerie),
          notificationsControllerProvider.overrideWith(_SansNotifications.new),
        ],
      );
      // Écran ouvert : la conversation est suivie.
      container.listen(messagesProvider('c1'), (_, _) {});
      container.listen(realtimeEventsProvider, (_, _) {});
      await container.read(messagesProvider('c1').future);
    });

    tearDown(() {
      container.dispose();
      evenements.close();
    });

    test(
      'message reçu (temps réel puis relecture, plusieurs fois) : affiché une seule fois',
      () async {
        final m2 = _json('m2', '2026-10-28T10:01:00');
        messagerie.serveur.add(m2);

        evenements.add(RealtimeEvent(RealtimeEventType.message, m2));
        await _attendre();
        evenements.add(RealtimeEvent(RealtimeEventType.message, m2));
        await _attendre();
        container
            .read(messagesProvider('c1').notifier)
            .ajouter(Message.fromJson(m2));

        expect(affiches(), ['m1', 'm2']);
      },
    );

    test('message supprimé par son auteur : retiré', () async {
      messagerie.serveur.clear();
      evenements.add(
        const RealtimeEvent(RealtimeEventType.message, {
          'conversationId': 'c1',
          'id': 'm1',
          'supprime': true,
        }),
      );
      await _attendre();

      expect(affiches(), isEmpty);
    });

    test('événement d’une autre conversation : ignoré', () async {
      evenements.add(
        RealtimeEvent(RealtimeEventType.message, {
          ..._json('autre', '2026-10-28T10:02:00'),
          'conversationId': 'c2',
        }),
      );
      await _attendre();

      expect(affiches(), ['m1']);
    });

    test(
      'reconnexion : les messages arrivés pendant la coupure apparaissent',
      () async {
        messagerie.serveur.add(_json('m3', '2026-10-28T10:03:00'));

        evenements.add(const RealtimeEvent(RealtimeEventType.reconnecte));
        await _attendre();

        expect(affiches(), ['m1', 'm3']);
      },
    );

    test(
      'message envoyé pendant une relecture plus ancienne : il ne disparaît pas',
      () async {
        messagerie.attente = Completer<void>();
        evenements.add(const RealtimeEvent(RealtimeEventType.reconnecte));
        await _attendre();

        // Réponse à l'envoi, arrivée avant la fin de la relecture (qui ne le connaît pas).
        container
            .read(messagesProvider('c1').notifier)
            .ajouter(Message.fromJson(_json('m4', '2026-10-28T10:04:00')));
        messagerie.attente!.complete();
        messagerie.attente = null;
        await _attendre();

        expect(affiches(), ['m1', 'm4']);
      },
    );
  });
}
