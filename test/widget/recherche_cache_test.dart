import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:psyavocat_front/core/widgets/app_search_field.dart';
import 'package:psyavocat_front/core/widgets/image_media.dart';

/// Liseré de focus : bordure visible autour de la barre.
bool _focus(WidgetTester tester) {
  final barre = tester.widget<SearchBar>(find.byType(SearchBar));
  return barre.side!.resolve({})!.style != BorderStyle.none;
}

void main() {
  test(
    'cache des médias : même clé pour une image, quelle que soit la signature',
    () {
      const premiere =
          'https://compte.r2.cloudflarestorage.com/psyavocat-media/avatars/a.jpg?X-Amz-Signature=111';
      const suivante =
          'https://compte.r2.cloudflarestorage.com/psyavocat-media/avatars/a.jpg?X-Amz-Signature=222';

      expect(CacheMedias.cleDe(premiere), CacheMedias.cleDe(suivante));
      expect(
        CacheMedias.cleDe(premiere),
        'https://compte.r2.cloudflarestorage.com/psyavocat-media/avatars/a.jpg',
      );
      expect(
        CacheMedias.cleDe(
          'https://compte.r2.cloudflarestorage.com/psyavocat-media/avatars/b.jpg?X-Amz-Signature=111',
        ),
        isNot(CacheMedias.cleDe(premiere)),
      );
    },
  );

  testWidgets(
    'image pleine largeur (carte « populaires » de l’accueil) : pas de plantage',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SizedBox(
            width: 360,
            height: 140,
            child: ImageMedia(
              url:
                  'https://compte.r2.cloudflarestorage.com/psyavocat-media/c.jpg',
              largeurAffichee: double.infinity,
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'recherche : liseré au toucher, neutre en touchant ailleurs, croix pour effacer',
    (tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      String recherche = 'initiale';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AppSearchField(
                  hintText: 'Rechercher un avocat…',
                  effacable: true,
                  onChanged: (v) => recherche = v,
                ),
                const SizedBox(height: 200, child: Text('AILLEURS')),
              ],
            ),
          ),
        ),
      );

      expect(_focus(tester), isFalse);

      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      expect(_focus(tester), isTrue);

      await tester.enterText(find.byType(TextField), 'bail');
      await tester.pump();
      expect(recherche, 'bail');
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      expect(recherche, '');
      // L'effacement laisse la barre active.
      expect(_focus(tester), isTrue);

      await tester.tap(find.text('AILLEURS'));
      await tester.pumpAndSettle();
      expect(_focus(tester), isFalse);
    },
  );
}
