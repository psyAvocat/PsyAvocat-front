import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psyavocat_front/core/theme/app_universe.dart';
import 'package:psyavocat_front/core/theme/universe_provider.dart';
import 'package:psyavocat_front/features/home/presentation/screens/home_screen.dart';
import 'package:psyavocat_front/features/notifications/data/models/notification_model.dart';
import 'package:psyavocat_front/features/notifications/data/repositories/notifications_repository.dart';
import 'package:psyavocat_front/features/notifications/presentation/controllers/notifications_controller.dart';
import 'package:psyavocat_front/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:psyavocat_front/features/professionnels/data/repositories/professionnels_repository.dart';
import 'package:psyavocat_front/features/profile/data/repositories/profil_repository.dart';
import 'package:psyavocat_front/features/rendez_vous/data/models/rendez_vous_model.dart';
import 'package:psyavocat_front/features/rendez_vous/data/repositories/rendez_vous_repository.dart';
import 'package:psyavocat_front/features/rendez_vous/presentation/controllers/rendez_vous_controller.dart';
import 'package:psyavocat_front/features/auth/data/repositories/session_repository.dart';
import 'package:psyavocat_front/features/orientation/data/repositories/orientation_repository.dart';
import 'mocks/orientation_test_doubles.dart';
import 'mocks/test_mocks.dart';

class TestUniverseNotifier extends UniverseNotifier {
  @override
  AppUniverse build() => AppUniverse.lawyer;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Restructuration Frontend — Notifications & Dynamic Badge Tests', () {
    test('unreadNotificationsCountProvider computes exact count of unread notifications', () async {
      final mockNotifs = [
        NotificationModel(
          id: '1',
          titre: 'T1',
          message: 'M1',
          date: DateTime.now(),
          type: 'RDV',
          isRead: false,
        ),
        NotificationModel(
          id: '2',
          titre: 'T2',
          message: 'M2',
          date: DateTime.now(),
          type: 'DOSSIER',
          isRead: true,
        ),
        NotificationModel(
          id: '3',
          titre: 'T3',
          message: 'M3',
          date: DateTime.now(),
          type: 'MESSAGE',
          isRead: false,
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          notificationsRepositoryProvider.overrideWithValue(MockNotificationsRepository(mockNotifs)),
        ],
      );
      addTearDown(container.dispose);

      await container.read(notificationsListProvider.future);
      final count = container.read(unreadNotificationsCountProvider);
      expect(count, equals(2));

      // Mark one as read
      await container.read(notificationsListProvider.notifier).markAsRead('1');
      final newCount = container.read(unreadNotificationsCountProvider);
      expect(newCount, equals(1));
    });

    testWidgets('HomeScreen renders dynamic notification badge when unread > 0', (tester) async {
      final mockNotifs = [
        NotificationModel(
          id: '1',
          titre: 'Rappel',
          message: 'Votre rdv',
          date: DateTime.now(),
          type: 'RDV',
          isRead: false,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUniverseProvider.overrideWith(TestUniverseNotifier.new),
            notificationsRepositoryProvider.overrideWithValue(MockNotificationsRepository(mockNotifs)),
            professionnelsRepositoryProvider.overrideWithValue(MockProfessionnelsRepository()),
            rendezVousRepositoryProvider.overrideWithValue(MockRendezVousRepository()),
            profilRepositoryProvider.overrideWithValue(MockProfilRepository()),
            sessionRepositoryProvider.overrideWithValue(FakeSessionRepository()),
            orientationRepositoryProvider.overrideWithValue(FakeOrientationRepository()),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Notification badge displays '1'
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('HomeScreen renders clean empty state when no upcoming appointments exist', (tester) async {
      final emptyRdvRepo = MockRendezVousRepository();
      // Emptied mock repository
      final container = ProviderContainer(
        overrides: [
          rendezVousRepositoryProvider.overrideWithValue(emptyRdvRepo),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUniverseProvider.overrideWith(TestUniverseNotifier.new),
            rendezVousListProvider.overrideWith(() => _EmptyRendezVousNotifier()),
            professionnelsRepositoryProvider.overrideWithValue(MockProfessionnelsRepository()),
            notificationsRepositoryProvider.overrideWithValue(MockNotificationsRepository([])),
            profilRepositoryProvider.overrideWithValue(MockProfilRepository()),
            sessionRepositoryProvider.overrideWithValue(FakeSessionRepository()),
            orientationRepositoryProvider.overrideWithValue(FakeOrientationRepository()),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Aucun rendez-vous à venir.'), findsOneWidget);
      expect(find.text('Trouver un avocat'), findsOneWidget);
      // Prénom réel issu de GET /me.
      expect(find.text('Bonjour Awa'), findsOneWidget);
    });

    testWidgets('NotificationsScreen displays empty state when notifications list is empty', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUniverseProvider.overrideWith(TestUniverseNotifier.new),
            notificationsRepositoryProvider.overrideWithValue(MockNotificationsRepository([])),
          ],
          child: const MaterialApp(
            home: NotificationsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Aucune notification'), findsOneWidget);
      expect(find.text('Vous êtes à jour avec vos rappels et messages.'), findsOneWidget);
    });
  });
}

class _EmptyRendezVousNotifier extends RendezVousNotifier {
  @override
  Future<List<RendezVousItem>> build() async => [];
}
