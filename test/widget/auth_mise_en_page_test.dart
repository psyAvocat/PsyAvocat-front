import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:psyavocat_front/core/network/network_providers.dart';
import 'package:psyavocat_front/core/theme/app_theme.dart';
import 'package:psyavocat_front/core/theme/app_universe.dart';
import 'package:psyavocat_front/core/widgets/app_curved_header.dart';
import 'package:psyavocat_front/features/auth/data/repositories/auth_repository.dart';
import 'package:psyavocat_front/features/auth/presentation/screens/login_screen.dart';
import 'package:psyavocat_front/features/auth/presentation/screens/register_screen.dart';

class _Auth extends Fake implements AuthRepository {
  @override
  User? get currentUser => null;

  @override
  Stream<User?> get authStateChanges => Stream.value(null);
}

/// Connexion et inscription tiennent dans l'écran, du petit téléphone
/// (360 × 640) au grand, sans débordement ni défilement.
void main() {
  for (final ecran in ['connexion', 'inscription']) {
    for (final taille in const [
      Size(360, 640),
      Size(360, 740),
      Size(393, 852),
      Size(412, 915),
    ]) {
      testWidgets(
        '$ecran ${taille.width.toInt()} × ${taille.height.toInt()} : tient dans l’écran',
        (tester) async {
          GoogleFonts.config.allowRuntimeFetching = false;
          tester.view.physicalSize = taille * 3;
          tester.view.devicePixelRatio = 3;
          tester.view.padding = const FakeViewPadding(
            top: 24 * 3,
            bottom: 16 * 3,
          );
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            ProviderScope(
              overrides: [authRepositoryProvider.overrideWithValue(_Auth())],
              child: MaterialApp(
                theme: AppTheme.buildTheme(AppUniverse.neutral),
                home: ecran == 'connexion'
                    ? const LoginScreen()
                    : const RegisterScreen(),
              ),
            ),
          );
          await tester.pumpAndSettle();
          // Tout tient dans l'écran : rien ne déborde, la page ne bouge pas.
          expect(tester.takeException(), isNull);
          final position = tester
              .state<ScrollableState>(find.byType(Scrollable).first)
              .position;
          expect(position.maxScrollExtent, 0);
        },
      );
    }
  }

  testWidgets(
    'connexion : clavier ouvert, la page garde sa mise en page ; toucher ailleurs retire le focus',
    (tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      tester.view.physicalSize = const Size(393, 852) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authRepositoryProvider.overrideWithValue(_Auth())],
          child: MaterialApp(
            theme: AppTheme.buildTheme(AppUniverse.neutral),
            home: const LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final enTete = tester.getSize(find.byType(AppCurvedHeader)).height;

      await tester.tap(find.byType(TextField).first);
      // Clavier ouvert : un tiers de l'écran environ.
      tester.view.viewInsets = const FakeViewPadding(bottom: 300 * 3);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(AppCurvedHeader)).height, enTete);
      final champ = tester.widget<EditableText>(
        find.byType(EditableText).first,
      );
      expect(champ.focusNode.hasFocus, isTrue);

      tester.view.resetViewInsets();
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(200, 120));
      await tester.pumpAndSettle();
      expect(champ.focusNode.hasFocus, isFalse);
    },
  );
}
