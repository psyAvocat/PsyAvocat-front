import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:psyavocat_front/core/errors/app_exception.dart';
import 'package:psyavocat_front/core/network/network_providers.dart';
import 'package:psyavocat_front/core/router/app_router.dart';
import 'package:psyavocat_front/core/router/app_routes.dart';
import 'package:psyavocat_front/core/router/startup_splash.dart';
import 'package:psyavocat_front/core/services/app_preferences_service.dart';
import 'package:psyavocat_front/core/widgets/widgets.dart';
import 'package:psyavocat_front/features/auth/data/models/current_user.dart';
import 'package:psyavocat_front/features/auth/data/repositories/auth_repository.dart';
import 'package:psyavocat_front/features/auth/data/repositories/session_repository.dart';
import 'package:psyavocat_front/features/auth/presentation/controllers/session_controller.dart';
import 'package:psyavocat_front/features/auth/presentation/screens/login_screen.dart';
import 'package:psyavocat_front/features/profile/data/models/profil_model.dart';
import 'package:psyavocat_front/features/profile/data/repositories/profil_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeUser extends Fake implements User {
  @override
  String get uid => 'uid';
}

class _FakeCredential extends Fake implements UserCredential {}

/// Firebase simulé : `authStateChanges` émet l'utilisateur courant à
/// l'abonnement, puis chaque connexion / déconnexion. Comme le SDK réel,
/// se reconnecter au compte déjà connecté n'émet AUCUN événement.
class _FakeAuthRepository extends Fake implements AuthRepository {
  User? _current;
  final _changes = StreamController<User?>.broadcast();

  void _set(User? user) {
    final changed = (_current == null) != (user == null);
    _current = user;
    if (changed) _changes.add(user);
  }

  @override
  User? get currentUser => _current;

  @override
  Stream<User?> get authStateChanges async* {
    yield _current;
    yield* _changes.stream;
  }

  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async => null;

  @override
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    _set(_FakeUser());
    return _FakeCredential();
  }

  @override
  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    _set(_FakeUser());
    return _FakeCredential();
  }

  @override
  Future<void> signOut() async => _set(null);
}

/// Réponse réelle de `GET /me` pour un client inscrit depuis l'app.
/// Les [failures] premiers appels échouent (serveur momentanément injoignable).
class _FakeSessionRepository implements SessionRepository {
  int failures = 0;

  /// Profil client présent en base.
  bool hasProfile = true;

  @override
  Future<CurrentUser> getCurrentUser() async {
    if (failures > 0) {
      failures--;
      throw const NetworkException();
    }
    return CurrentUser.fromJson({
      'authenticated': true,
      'emailVerified': false,
      'firebaseUid': 'uid',
      'hasMetierProfile': hasProfile,
      'roles': [
        if (hasProfile) ...['ROLE_CLIENT', 'ROLE_PATIENT', 'ROLE_JUSTICIABLE'],
        'ROLE_USER',
      ],
      'telephone': '+22371800018',
      'actif': true,
      'userId': 'uid',
      'nom': 'Test',
      'prenom': 'Client',
      'email': 'client@example.com',
    });
  }
}

/// `POST /api/profil/client` : les [failures] premiers appels sont perdus
/// (réseau), les suivants créent le profil.
class _FakeProfilRepository extends Fake implements ProfilRepository {
  int failures = 0;
  int calls = 0;

  @override
  Future<ProfilModel> createClientProfile({
    required String nom,
    required String prenom,
    required String telephone,
  }) async {
    calls++;
    if (failures > 0) {
      failures--;
      throw const NetworkException();
    }
    _session.hasProfile = true;
    return ProfilModel.fromJson({'id': 'uid', 'nom': nom, 'prenom': prenom});
  }
}

final _session = _FakeSessionRepository();
final _profil = _FakeProfilRepository();

Future<ProviderContainer> _startApp(WidgetTester tester) async {
  _session
    ..failures = 0
    ..hasProfile = true;
  _profil
    ..failures = 0
    ..calls = 0;
  GoogleFonts.config.allowRuntimeFetching = false;
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({'has_seen_onboarding': true});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
      sessionRepositoryProvider.overrideWithValue(_session),
      profilRepositoryProvider.overrideWithValue(_profil),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: Consumer(
        builder: (context, ref, _) => MaterialApp.router(
          scaffoldMessengerKey: AppNotification.messengerKey,
          routerConfig: ref.watch(appRouterProvider),
        ),
      ),
    ),
  );
  // Splash (durée minimale) puis connexion.
  await tester.pump(StartupSplashNotifier.minimum);
  await tester.pumpAndSettle();
  return container;
}

String _location(ProviderContainer container) => container
    .read(appRouterProvider)
    .routerDelegate
    .currentConfiguration
    .uri
    .path;

Future<void> _login(WidgetTester tester) async {
  await tester.enterText(find.byType(TextFormField).at(0), 'a@example.com');
  await tester.enterText(find.byType(TextFormField).at(1), 'TestPass123!');
  await tester.tap(find.widgetWithText(AppButton, 'Se connecter'));
  await tester.pumpAndSettle();
}

Future<void> _register(WidgetTester tester) async {
  await tester.tap(find.text("S'inscrire"));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextFormField).at(0), 'Ramla');
  await tester.enterText(find.byType(TextFormField).at(1), 'Diarra');
  await tester.ensureVisible(find.text('Continuer'));
  await tester.tap(find.text('Continuer'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextFormField).at(0), 'a@example.com');
  await tester.enterText(find.byType(TextFormField).at(1), '+223 76 12 34 56');
  await tester.ensureVisible(find.text('Continuer'));
  await tester.tap(find.text('Continuer'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextFormField).at(0), 'TestPass123!');
  await tester.enterText(find.byType(TextFormField).at(1), 'TestPass123!');
  await tester.ensureVisible(find.byType(Checkbox));
  await tester.tap(find.byType(Checkbox));
  await tester.pump();
  await tester.ensureVisible(find.text('Créer mon compte'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Créer mon compte'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('connexion d’un client inscrit : choix de l’univers', (
    tester,
  ) async {
    final container = await _startApp(tester);
    expect(_location(container), AppRoutes.login);

    await _login(tester);
    expect(_location(container), AppRoutes.universeSelection);

    // Laisse expirer la notification « Connexion réussie ».
    await tester.pump(const Duration(seconds: 10));
  });

  testWidgets('inscription, déconnexion puis connexion : choix de l’univers', (
    tester,
  ) async {
    final container = await _startApp(tester);

    _session.hasProfile = false;
    await _register(tester);
    expect(_location(container), AppRoutes.universeSelection);

    await container.read(sessionControllerProvider.notifier).signOut();
    await tester.pumpAndSettle();
    expect(_location(container), AppRoutes.login);

    await _login(tester);
    expect(_location(container), AppRoutes.universeSelection);

    await tester.pump(const Duration(seconds: 10));
  });

  testWidgets(
    'serveur injoignable après l’inscription, puis connexion au même compte',
    (tester) async {
      final container = await _startApp(tester);

      // Compte créé, mais GET /me échoue : Firebase reste connecté.
      _session
        ..hasProfile = false
        ..failures = 1;
      await _register(tester);
      expect(
        container.read(sessionControllerProvider).status,
        SessionStatus.error,
      );

      AppNotification.messengerKey.currentState!.clearSnackBars();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Se connecter'));
      await tester.tap(find.text('Se connecter'));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);

      // Même compte : Firebase n'émet aucun événement, /me doit être relancé.
      await _login(tester);
      expect(_location(container), AppRoutes.universeSelection);

      await tester.pump(const Duration(seconds: 10));
    },
  );

  testWidgets(
    'profil perdu à l’inscription : créé à la connexion suivante, sans écran',
    (tester) async {
      final container = await _startApp(tester);

      // Serveur injoignable pendant l'inscription puis la vérification.
      _session.hasProfile = false;
      _profil.failures = 2;
      await _register(tester);
      expect(
        container.read(sessionControllerProvider).status,
        SessionStatus.error,
      );
      expect(_session.hasProfile, isFalse);

      AppNotification.messengerKey.currentState!.clearSnackBars();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Se connecter'));
      await tester.tap(find.text('Se connecter'));
      await tester.pumpAndSettle();

      await _login(tester);
      expect(_profil.calls, 3);
      expect(_session.hasProfile, isTrue);
      expect(_location(container), AppRoutes.universeSelection);

      await tester.pump(const Duration(seconds: 10));
    },
  );

  testWidgets(
    'compte sans profil ni informations d’inscription : réinscription demandée',
    (tester) async {
      final container = await _startApp(tester);

      _session.hasProfile = false;
      await _login(tester);

      expect(_profil.calls, 0);
      expect(container.read(authRepositoryProvider).currentUser, isNull);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.textContaining('Inscrivez-vous à nouveau'), findsOneWidget);

      await tester.pump(const Duration(seconds: 10));
    },
  );
}
