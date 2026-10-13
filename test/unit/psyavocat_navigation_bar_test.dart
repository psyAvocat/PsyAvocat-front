import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psyavocat_front/core/widgets/navigation/psyavocat_navigation_bar.dart';
import 'package:psyavocat_front/features/navigation/presentation/navigation_destinations.dart';
import 'package:psyavocat_front/core/theme/app_universe.dart';

void main() {
  Widget buildNavBar({
    required int currentIndex,
    required AppUniverse universe,
    required ValueChanged<int> onDestinationSelected,
  }) {
    return MaterialApp(
      home: Scaffold(
        bottomNavigationBar: PsyAvocatNavigationBar(
          destinations: navigationDestinationsFor(universe),
          currentIndex: currentIndex,
          onDestinationSelected: onDestinationSelected,
        ),
      ),
    );
  }

  group('PsyAvocatNavigationBar Tests', () {
    testWidgets('renders all 5 destinations in Psychologue universe', (
      tester,
    ) async {
      int selected = 0;

      await tester.pumpWidget(
        buildNavBar(
          currentIndex: 0,
          universe: AppUniverse.psychologist,
          onDestinationSelected: (idx) => selected = idx,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Accueil'), findsOneWidget);
      expect(find.text('Conseils'), findsOneWidget);
      expect(find.text('Rendez-vous'), findsOneWidget);
      expect(find.text('Profil'), findsOneWidget);

      // Le bouton central possède l'icône de psychologie
      expect(find.byIcon(Icons.psychology_rounded), findsOneWidget);

      // Clic sur l'onglet Conseils (index 1)
      await tester.tap(find.text('Conseils'));
      await tester.pumpAndSettle();
      expect(selected, equals(1));

      // Clic sur le bouton central (index 2)
      await tester.tap(find.byIcon(Icons.psychology_rounded));
      await tester.pumpAndSettle();
      expect(selected, equals(2));

      // Clic sur Rendez-vous (index 3)
      await tester.tap(find.text('Rendez-vous'));
      await tester.pumpAndSettle();
      expect(selected, equals(3));

      // Clic sur Profil (index 4)
      await tester.tap(find.text('Profil'));
      await tester.pumpAndSettle();
      expect(selected, equals(4));
    });

    testWidgets('renders all 5 destinations in Avocat universe', (
      tester,
    ) async {
      int selected = 0;

      await tester.pumpWidget(
        buildNavBar(
          currentIndex: 0,
          universe: AppUniverse.lawyer,
          onDestinationSelected: (idx) => selected = idx,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Accueil'), findsOneWidget);
      expect(find.text('Articles'), findsOneWidget);
      expect(find.text('Rendez-vous'), findsOneWidget);
      expect(find.text('Profil'), findsOneWidget);

      // Le bouton central possède l'icône de justice/balance
      expect(find.byIcon(Icons.gavel_rounded), findsOneWidget);

      // Clic sur l'onglet Articles (index 1)
      await tester.tap(find.text('Articles'));
      await tester.pumpAndSettle();
      expect(selected, equals(1));
    });

    testWidgets('smoothly animates when currentIndex changes externally', (
      tester,
    ) async {
      int currentIndex = 0;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: ElevatedButton(
                  onPressed: () => setState(() => currentIndex = 3),
                  child: const Text('Change to 3'),
                ),
                bottomNavigationBar: PsyAvocatNavigationBar(
                  destinations: navigationDestinationsFor(
                    AppUniverse.psychologist,
                  ),
                  currentIndex: currentIndex,
                  onDestinationSelected: (_) {},
                ),
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      // Trigger programmatic index change
      await tester.tap(find.text('Change to 3'));
      // Mid-animation frame
      await tester.pump(const Duration(milliseconds: 150));
      // End animation
      await tester.pumpAndSettle();

      expect(find.text('Rendez-vous'), findsOneWidget);
    });
  });
}
