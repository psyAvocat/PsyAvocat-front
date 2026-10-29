import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:psyavocat_front/core/realtime/realtime_service.dart';
import 'package:psyavocat_front/core/theme/app_theme.dart';
import 'package:psyavocat_front/core/theme/app_universe.dart';
import 'package:psyavocat_front/core/theme/universe_provider.dart';
import 'package:psyavocat_front/features/contenus/data/models/contenu_model.dart';
import 'package:psyavocat_front/features/contenus/data/repositories/contenus_repository.dart';
import 'package:psyavocat_front/features/contenus/presentation/screens/contenu_detail_screen.dart';

class _UniversAvocat extends UniverseNotifier {
  @override
  AppUniverse build() => AppUniverse.lawyer;
}

class _FauxContenus implements ContenusRepository {
  @override
  Future<Publication> getPublication(String id) async => Publication(
    id: id,
    type: 'ARTICLE',
    titre: 'Vos droits en cas de licenciement',
    description: 'Ce qu’il faut savoir avant de contester.',
    contenu: [
      for (var i = 1; i <= 30; i++) 'Paragraphe $i : explication détaillée.',
      '- premier point\n- second point',
    ].join('\n\n'),
    auteurId: 'avocat-1',
    auteurPrenom: 'Thomas',
    auteurNom: 'Bernard',
    tempsLectureMinutes: 4,
  );

  @override
  Future<List<Publication>> rechercher({
    required String type,
    String? q,
    String? specialiteId,
    PublicationSort tri = PublicationSort.recent,
    String? auteurId,
  }) async => const [];
}

/// Position du bouton « Quitter » : à zéro quand il est affiché.
Offset _decalageBouton(WidgetTester tester) => tester
    .widget<FractionalTranslation>(
      find.byKey(const ValueKey('quitter-position')),
    )
    .translation;

void main() {
  testWidgets(
    'lecture : « Quitter » s’efface en descendant et revient en remontant',
    (tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUniverseProvider.overrideWith(_UniversAvocat.new),
            contenusRepositoryProvider.overrideWithValue(_FauxContenus()),
            realtimeEventsProvider.overrideWith((ref) => const Stream.empty()),
          ],
          child: MaterialApp(
            theme: AppTheme.buildTheme(AppUniverse.lawyer),
            home: const ContenuDetailScreen(contenuId: 'c1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Titre dans le texte, et dans la barre du haut (visible une fois l'image dépassée).
      expect(find.text('Vos droits en cas de licenciement'), findsNWidgets(2));
      expect(find.text('premier point'), findsOneWidget);
      expect(_decalageBouton(tester), Offset.zero);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(_decalageBouton(tester), isNot(Offset.zero));

      await tester.drag(find.byType(CustomScrollView), const Offset(0, 120));
      await tester.pumpAndSettle();
      expect(_decalageBouton(tester), Offset.zero);

      // En fin de lecture, le bouton est toujours proposé.
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -20000));
      await tester.pumpAndSettle();
      expect(_decalageBouton(tester), Offset.zero);
      expect(find.text('Voir ses autres articles'), findsOneWidget);
    },
  );
}
