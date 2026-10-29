import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psyavocat_front/core/realtime/realtime_service.dart';
import 'package:psyavocat_front/features/messagerie/data/models/messagerie_model.dart';
import 'package:psyavocat_front/features/messagerie/presentation/controllers/conversations_providers.dart';

void main() {
  test('Conversation : lit le statut « en ligne » du correspondant', () {
    final enLigne = Conversation.fromJson({
      'id': 'c1',
      'correspondantId': 'pro-1',
      'correspondantEnLigne': true,
    });
    final sansChamp = Conversation.fromJson({'id': 'c2'});

    expect(enLigne.correspondantEnLigne, isTrue);
    expect(sansChamp.correspondantEnLigne, isFalse);
  });

  test('Présence : état initial des conversations, puis événements temps réel', () async {
    final events = StreamController<RealtimeEvent>();
    final container = ProviderContainer(
      overrides: [realtimeEventsProvider.overrideWith((ref) => events.stream)],
    );
    addTearDown(() {
      container.dispose();
      events.close();
    });

    // Écoute active, comme un écran ouvert.
    container.listen(presenceProvider, (_, _) {});
    container.listen(realtimeEventsProvider, (_, _) {});

    container.read(presenceProvider.notifier).initialiser([
      const Conversation(
        id: 'c1',
        correspondantId: 'pro-1',
        correspondantNom: 'Diallo',
        correspondantPrenom: 'Awa',
        messagesNonLus: 0,
        correspondantEnLigne: true,
      ),
    ]);
    expect(container.read(presenceProvider)['pro-1'], isTrue);

    events.add(
      const RealtimeEvent(RealtimeEventType.presence, {
        'utilisateurId': 'pro-1',
        'enLigne': false,
      }),
    );
    await Future<void>.delayed(Duration.zero);
    expect(container.read(presenceProvider)['pro-1'], isFalse);

    events.add(
      const RealtimeEvent(RealtimeEventType.presence, {
        'utilisateurId': 'pro-2',
        'enLigne': true,
      }),
    );
    await Future<void>.delayed(Duration.zero);
    expect(container.read(presenceProvider)['pro-2'], isTrue);
  });
}
