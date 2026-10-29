import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:psyavocat_front/core/realtime/realtime_service.dart';
import 'package:psyavocat_front/core/theme/app_universe.dart';
import 'package:psyavocat_front/core/theme/universe_provider.dart';
import 'package:psyavocat_front/features/contenus/data/models/contenu_model.dart';
import 'package:psyavocat_front/features/contenus/data/repositories/contenus_repository.dart';
import 'package:psyavocat_front/features/contenus/presentation/screens/professionnel_publications_screen.dart';

class _UniversAvocat extends UniverseNotifier {
  @override
  AppUniverse build() => AppUniverse.lawyer;
}

/// Mémorise les recherches envoyées à l'API.
class _FauxContenus implements ContenusRepository {
  final appels = <({String? auteurId, String? q, PublicationSort tri})>[];

  @override
  Future<List<Publication>> rechercher({
    required String type,
    String? q,
    String? specialiteId,
    PublicationSort tri = PublicationSort.recent,
    String? auteurId,
  }) async {
    appels.add((auteurId: auteurId, q: q, tri: tri));
    return [
      Publication(id: 'p1', type: 'ARTICLE', titre: 'Article ${q ?? ''}'),
    ];
  }

  @override
  Future<Publication> getPublication(String id) => throw UnimplementedError();
}

void main() {
  testWidgets(
    'articles d’un professionnel : recherche et tri envoyés à l’API',
    (tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      final contenus = _FauxContenus();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUniverseProvider.overrideWith(_UniversAvocat.new),
            contenusRepositoryProvider.overrideWithValue(contenus),
            realtimeEventsProvider.overrideWith((ref) => const Stream.empty()),
          ],
          child: const MaterialApp(
            home: ProfessionnelPublicationsScreen(
              professionnelId: 'avocat-1',
              professionnelNom: 'Me Traoré',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Par défaut : ses publications, les plus récentes d'abord.
      expect(contenus.appels.last, (
        auteurId: 'avocat-1',
        q: null,
        tri: PublicationSort.recent,
      ));

      await tester.enterText(find.byType(SearchBar), 'bail');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(contenus.appels.last, (
        auteurId: 'avocat-1',
        q: 'bail',
        tri: PublicationSort.recent,
      ));

      await tester.tap(find.text('Populaires'));
      await tester.pumpAndSettle();
      expect(contenus.appels.last, (
        auteurId: 'avocat-1',
        q: 'bail',
        tri: PublicationSort.populaire,
      ));
    },
  );
}
