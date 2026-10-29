import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:psyavocat_front/core/network/network_providers.dart';
import 'package:psyavocat_front/core/realtime/realtime_service.dart';
import 'package:psyavocat_front/core/theme/app_universe.dart';
import 'package:psyavocat_front/core/theme/universe_provider.dart';
import 'package:psyavocat_front/features/auth/data/repositories/auth_repository.dart';
import 'package:psyavocat_front/features/messagerie/data/models/messagerie_model.dart';
import 'package:psyavocat_front/features/messagerie/data/repositories/messagerie_repository.dart';
import 'package:psyavocat_front/features/messagerie/presentation/screens/conversation_detail_screen.dart';
import 'package:psyavocat_front/features/messagerie/presentation/widgets/avatar_presence.dart';
import 'package:psyavocat_front/features/notifications/data/models/notification_model.dart';
import 'package:psyavocat_front/features/notifications/presentation/controllers/notifications_controller.dart';

class _UniversAvocat extends UniverseNotifier {
  @override
  AppUniverse build() => AppUniverse.lawyer;
}

class _SansNotifications extends NotificationsController {
  @override
  Future<List<NotificationItem>> build() async => const [];

  @override
  Future<void> refresh() async {}
}

class _Auth extends Fake implements AuthRepository {
  @override
  get currentUser => null;
}

class _FausseMessagerie extends Fake implements MessagerieRepository {
  @override
  Future<List<Conversation>> getConversations() async => const [
    Conversation(
      id: 'c1',
      correspondantId: 'psy-1',
      correspondantPrenom: 'Claire',
      correspondantNom: 'Martin',
      correspondantType: 'PSYCHOLOGUE',
      messagesNonLus: 0,
      correspondantEnLigne: true,
    ),
  ];

  @override
  Future<List<Message>> getMessages(String conversationId) async => const [];
}

void main() {
  testWidgets(
    'discussion ouverte depuis une notification : même en-tête que depuis la messagerie',
    (tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            // Univers Avocat courant : la discussion avec une psychologue garde son identité.
            currentUniverseProvider.overrideWith(_UniversAvocat.new),
            messagerieRepositoryProvider.overrideWithValue(_FausseMessagerie()),
            authRepositoryProvider.overrideWithValue(_Auth()),
            notificationsControllerProvider.overrideWith(
              _SansNotifications.new,
            ),
            realtimeEventsProvider.overrideWith((ref) => const Stream.empty()),
          ],
          // Comme une notification : seul l'identifiant de la conversation est connu.
          child: const MaterialApp(
            home: ConversationDetailScreen(conversationId: 'c1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dr Claire Martin'), findsOneWidget);
      expect(find.text('Psychologue'), findsOneWidget);
      // Présence : une pastille verte sur la photo, plus de texte « En ligne ».
      expect(find.text('En ligne'), findsNothing);
      expect(
        tester.widget<AvatarPresence>(find.byType(AvatarPresence)).enLigne,
        isTrue,
      );
    },
  );
}
