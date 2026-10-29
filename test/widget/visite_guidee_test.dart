import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:psyavocat_front/core/services/app_preferences_service.dart';
import 'package:psyavocat_front/core/theme/app_universe.dart';
import 'package:psyavocat_front/core/theme/universe_provider.dart';
import 'package:psyavocat_front/core/widgets/cible_visite.dart';
import 'package:psyavocat_front/features/auth/presentation/controllers/session_controller.dart';
import 'package:psyavocat_front/features/onboarding/presentation/visite_guidee_controller.dart';
import 'package:psyavocat_front/features/onboarding/presentation/widgets/visite_guidee.dart';
import 'package:psyavocat_front/features/profile/data/models/profil_model.dart';
import 'package:psyavocat_front/features/profile/data/repositories/profil_repository.dart';
import 'package:psyavocat_front/features/profile/presentation/controllers/profil_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _UniversPsy extends UniverseNotifier {
  @override
  AppUniverse build() => AppUniverse.psychologist;
}

class _Profil extends ProfilNotifier {
  _Profil(this.vue);

  final bool vue;

  @override
  Future<ProfilModel?> build() async => ProfilModel(
    id: 'uid-1',
    nom: 'Traoré',
    prenom: 'Awa',
    email: 'awa@test.fr',
    typeUtilisateur: 'CLIENT',
    visiteGuideeVue: vue,
  );
}

class _FauxProfils extends Fake implements ProfilRepository {
  int marquages = 0;

  @override
  Future<void> marquerVisiteGuideeVue() async => marquages++;
}

Future<ProviderContainer> _conteneur({
  bool vueSurLeCompte = false,
  Map<String, Object> prefs = const {},
  _FauxProfils? profils,
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final conteneur = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(
        await SharedPreferences.getInstance(),
      ),
      signedInAccountProvider.overrideWithValue('uid-1'),
      currentProfilProvider.overrideWith(() => _Profil(vueSurLeCompte)),
      currentUniverseProvider.overrideWith(_UniversPsy.new),
      profilRepositoryProvider.overrideWithValue(profils ?? _FauxProfils()),
    ],
  );
  addTearDown(conteneur.dispose);
  conteneur.listen(visiteGuideeProvider, (_, _) {});
  await conteneur.read(currentProfilProvider.future);
  return conteneur;
}

void main() {
  group('Visite guidée : une seule fois par compte', () {
    test(
      'nouveau compte : proposée, puis plus jamais une fois terminée',
      () async {
        final profils = _FauxProfils();
        final conteneur = await _conteneur(profils: profils);
        expect(conteneur.read(visiteGuideeProvider), isTrue);

        await conteneur.read(visiteGuideeProvider.notifier).terminer();

        expect(conteneur.read(visiteGuideeProvider), isFalse);
        expect(profils.marquages, 1);
        expect(
          conteneur
              .read(appPreferencesServiceProvider)
              .visiteGuideeVue('uid-1'),
          isTrue,
        );
      },
    );

    test('déjà vue sur un autre appareil : pas reproposée', () async {
      final conteneur = await _conteneur(vueSurLeCompte: true);

      expect(conteneur.read(visiteGuideeProvider), isFalse);
    });

    test(
      'vue sur cet appareil (serveur injoignable à ce moment) : pas reproposée',
      () async {
        final conteneur = await _conteneur(
          prefs: {'visite_guidee_vue_uid-1': true},
        );

        expect(conteneur.read(visiteGuideeProvider), isFalse);
      },
    );

    test(
      'relancée depuis les Paramètres : affichée même si déjà vue',
      () async {
        final conteneur = await _conteneur(vueSurLeCompte: true);

        conteneur.read(visiteGuideeProvider.notifier).relancer();
        expect(conteneur.read(visiteGuideeProvider), isTrue);

        await conteneur.read(visiteGuideeProvider.notifier).terminer();
        expect(conteneur.read(visiteGuideeProvider), isFalse);
      },
    );
  });

  testWidgets(
    'écrans de la visite : accueil, étapes sur les vrais éléments, passer',
    (tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      // Téléphone étroit (360 × 760) : la bulle ne doit pas déborder.
      tester.view.physicalSize = const Size(1080, 2280);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final conteneur = await _conteneur();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: conteneur,
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) => Stack(
                children: [
                  const Scaffold(
                    body: Align(
                      alignment: Alignment.topRight,
                      child: CibleVisite(
                        id: 'notifications',
                        child: Icon(Icons.notifications_outlined),
                      ),
                    ),
                  ),
                  if (ref.watch(visiteGuideeProvider))
                    const Positioned.fill(child: VisiteGuidee()),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bienvenue sur PsyAvocat'), findsOneWidget);

      await tester.tap(find.text('Commencer'));
      await tester.pumpAndSettle();
      expect(find.text('Vos notifications'), findsOneWidget);
      expect(find.text('1 sur 5'), findsOneWidget);

      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();
      // Univers Psychologue : l'onglet présenté est celui des conseils.
      expect(find.text('Conseils'), findsOneWidget);

      await tester.tap(find.text('Passer'));
      await tester.pumpAndSettle();
      expect(find.byType(VisiteGuidee), findsNothing);
    },
  );
}
