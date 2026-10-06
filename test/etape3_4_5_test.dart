import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psyavocat_front/core/theme/app_universe.dart';
import 'package:psyavocat_front/core/theme/universe_provider.dart';
import 'package:psyavocat_front/features/professionnels/data/repositories/professionnels_repository.dart';
import 'package:psyavocat_front/features/professionnels/presentation/screens/professionnel_detail_screen.dart';
import 'package:psyavocat_front/features/rendez_vous/data/repositories/rendez_vous_repository.dart';
import 'package:psyavocat_front/features/rendez_vous/presentation/controllers/rendez_vous_controller.dart';
import 'package:psyavocat_front/features/rendez_vous/presentation/screens/choix_creneau_screen.dart';
import 'package:psyavocat_front/features/rendez_vous/presentation/screens/rendez_vous_confirmation_screen.dart';
import 'package:psyavocat_front/features/rendez_vous/presentation/screens/rendez_vous_screen.dart';
import 'mocks/test_mocks.dart';

class FakeLawyerUniverseNotifier extends UniverseNotifier {
  @override
  AppUniverse build() => AppUniverse.lawyer;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Étape 3 — ProfessionnelsRepository Unit Tests', () {
    test('searchProfessionnels returns lawyers and psychologists', () async {
      final repo = MockProfessionnelsRepository();
      final all = await repo.searchProfessionnels();
      expect(all.length, greaterThanOrEqualTo(3));
      expect(all.any((p) => p.fullName.contains('Sangaré')), isTrue);
      expect(all.any((p) => p.fullName.contains('Lambert')), isTrue);
    });

    test('searchProfessionnels filters by type', () async {
      final repo = MockProfessionnelsRepository();
      final avocats = await repo.searchProfessionnels(type: 'AVOCAT');
      final psys = await repo.searchProfessionnels(type: 'PSYCHOLOGUE');

      expect(avocats.map((p) => p.fullName), everyElement(contains('Maître')));
      expect(psys.map((p) => p.fullName), everyElement(contains('Dr.')));
    });

    test('getProfessionnelById returns full detail with tarifications and dispo', () async {
      final repo = MockProfessionnelsRepository();
      final pro = await repo.getProfessionnelById('avocat-sangare');
      expect(pro, isNotNull);
      expect(pro!.nom, contains('Sangaré'));
      expect(pro.titre, equals('Avocat au barreau'));
      expect(pro.isAvocat, isTrue);
      expect(pro.tarifs.length, greaterThanOrEqualTo(2));
      expect(pro.tarifs.first.montantFcfa, greaterThan(0));
      expect(pro.disponibilites.isNotEmpty, isTrue);
    });
  });

  group('Étape 4 & 5 — RendezVousController Logic Tests', () {
    test('Initial state contains seeded appointments', () async {
      final mockRepo = MockRendezVousRepository();
      final container = ProviderContainer(
        overrides: [
          rendezVousRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final rdvList = await container.read(rendezVousListProvider.future);
      expect(rdvList.isNotEmpty, isTrue);
      expect(rdvList.any((r) => r.status == 'Confirmé'), isTrue);
    });

    test('addRendezVous inserts new booking at top of list with 20% acompte calculated', () async {
      final mockRepo = MockRendezVousRepository();
      final container = ProviderContainer(
        overrides: [
          rendezVousRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      await container.read(rendezVousListProvider.future);

      final notifier = container.read(rendezVousListProvider.notifier);
      await notifier.addRendezVous(
        proId: 'avocat-sangare',
        proName: 'Maître Sangaré',
        proRole: 'Avocat',
        specialty: 'Droit du travail',
        day: '18',
        month: 'Avr.',
        year: '2025',
        time: '14:00 - 15:00',
        mode: 'En ligne (visioconférence)',
        montantTotal: 200000,
        motif: 'Consultation litige contrat',
      );

      final updatedList = container.read(rendezVousListProvider).value!;
      expect(updatedList.first.proName, equals('Maître Sangaré'));
      expect(updatedList.first.status, equals('Confirmé'));
      expect(updatedList.first.montantTotal, equals(200000));
      // 20% of 200,000 = 40,000
      expect(updatedList.first.montantAcompte, equals(40000));
    });

    test('cancelRendezVous marks status as Annulé', () async {
      final mockRepo = MockRendezVousRepository();
      final container = ProviderContainer(
        overrides: [
          rendezVousRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final initialList = await container.read(rendezVousListProvider.future);
      final firstId = initialList.first.id;

      final notifier = container.read(rendezVousListProvider.notifier);
      notifier.cancelRendezVous(firstId);

      final updatedList = container.read(rendezVousListProvider).value!;
      final canceled = updatedList.firstWhere((r) => r.id == firstId);
      expect(canceled.status, equals('Annulé'));
    });
  });

  group('Étape 3 — ProfessionnelDetailScreen Widget Tests', () {
    testWidgets('Renders professional header, stats, bio, tariffs, and booking CTA', (tester) async {
      final mockRepo = MockProfessionnelsRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUniverseProvider.overrideWith(FakeLawyerUniverseNotifier.new),
            professionnelsRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: ProfessionnelDetailScreen(professionnelId: 'avocat-sangare'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify professional name and title
      expect(find.text('Maître Sangaré'), findsOneWidget);
      expect(find.text('Avocat au barreau'), findsOneWidget);

      // Verify stats badges
      expect(find.text('4.9'), findsOneWidget);
      expect(find.textContaining('138 avis'), findsOneWidget);

      // Verify Tarifs tab exists and FCFA is displayed
      expect(find.text('Tarifs'), findsOneWidget);
      expect(find.textContaining('FCFA'), findsWidgets);

      // Verify bottom CTA button
      expect(find.text('Prendre rendez-vous'), findsOneWidget);
    });
  });

  group('Étape 4 — ChoixCreneauScreen Widget Tests', () {
    testWidgets('Renders professional summary, mode toggle, time slots, and legal deposit note', (tester) async {
      final mockRepo = MockProfessionnelsRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUniverseProvider.overrideWith(FakeLawyerUniverseNotifier.new),
            professionnelsRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: ChoixCreneauScreen(professionnelId: 'avocat-sangare'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Title & Pro Name
      expect(find.text('Choix du créneau'), findsOneWidget);
      expect(find.text('Maître Sangaré'), findsOneWidget);

      // Modalité de consultation Visio / Cabinet
      expect(find.text('Modalité de consultation'), findsOneWidget);
      expect(find.text('En ligne (Visio)'), findsOneWidget);
      expect(find.text('Au cabinet'), findsOneWidget);

      // Legal deposit note (20%)
      expect(find.textContaining('20%'), findsWidgets);
      expect(find.textContaining('acompte'), findsWidgets);

      // CTA
      expect(find.text('Confirmer le rendez-vous'), findsOneWidget);
    });
  });

  group('Étape 5 — RendezVousConfirmationScreen Widget Tests', () {
    testWidgets('Renders success screen with recap details and deposit amount', (tester) async {
      final mockRepo = MockProfessionnelsRepository();
      final pro = (await mockRepo.getProfessionnelById('avocat-sangare'))!;
      final jour = pro.disponibilites.first;
      final tarif = pro.tarifs.first;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUniverseProvider.overrideWith(FakeLawyerUniverseNotifier.new),
            professionnelsRepositoryProvider.overrideWithValue(mockRepo),
            rendezVousRepositoryProvider.overrideWithValue(MockRendezVousRepository()),
          ],
          child: MaterialApp(
            home: RendezVousConfirmationScreen(
              bookingData: {
                'pro': pro,
                'jour': jour,
                'creneau': '14:00',
                'mode': 'En ligne (visioconférence)',
                'tarif': tarif,
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Header success text
      expect(find.text('Rendez-vous confirmé !'), findsOneWidget);
      expect(find.text('Maître Sangaré'), findsOneWidget);

      // Modalité and time
      expect(find.text('En ligne (visioconférence)'), findsOneWidget);
      expect(find.textContaining('14:00'), findsWidgets);

      // Acompte 20%
      expect(find.textContaining('40 000 FCFA'), findsOneWidget);

      // CTAs
      expect(find.text('Voir mes rendez-vous'), findsOneWidget);
      expect(find.text('Retour à l\'accueil'), findsOneWidget);
    });
  });

  group('Étape 5 — RendezVousScreen Live List Tests', () {
    testWidgets('RendezVousScreen renders tabs and lists confirmed appointments', (tester) async {
      final mockRdvRepo = MockRendezVousRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUniverseProvider.overrideWith(FakeLawyerUniverseNotifier.new),
            rendezVousRepositoryProvider.overrideWithValue(mockRdvRepo),
          ],
          child: const MaterialApp(
            home: RendezVousScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tab bar labels
      expect(find.textContaining('À venir'), findsOneWidget);
      expect(find.textContaining('Passés'), findsOneWidget);
      expect(find.textContaining('Annulés'), findsOneWidget);

      // Header title
      expect(find.text('Mes rendez-vous'), findsOneWidget);
    });
  });
}
