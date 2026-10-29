import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/controllers/session_controller.dart';
import '../../features/auth/presentation/screens/access_denied_screen.dart';
import '../../features/auth/presentation/screens/completer_profil_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/verify_email_screen.dart';
import '../../features/contenus/presentation/screens/contenu_detail_screen.dart';
import '../../features/contenus/presentation/screens/contenus_screen.dart';
import '../../features/contenus/presentation/screens/professionnel_publications_screen.dart';
import '../../features/dossiers/presentation/screens/dossier_detail_screen.dart';
import '../../features/dossiers/presentation/screens/dossier_prise_en_charge_screen.dart';
import '../../features/dossiers/presentation/screens/dossiers_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/messagerie/presentation/screens/conversation_detail_screen.dart';
import '../../features/messagerie/presentation/screens/messagerie_screen.dart';
import '../../features/navigation/presentation/main_navigation_shell.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/onboarding/presentation/screens/splash_screen.dart';
import '../../features/orientation/presentation/screens/orientation_intro_screen.dart';
import '../../features/orientation/presentation/screens/orientation_questionnaire_screen.dart';
import '../../features/orientation/presentation/screens/orientation_result_screen.dart';
import '../../features/paiements/presentation/screens/paiements_screen.dart';
import '../../features/professionnels/presentation/screens/professionnel_detail_screen.dart';
import '../../features/professionnels/presentation/screens/professionnels_list_screen.dart';
import '../../features/professionnels/presentation/screens/recherche_screen.dart';
import '../../features/profile/presentation/screens/fiche_patient_screen.dart';
import '../../features/profile/presentation/screens/help_support_screen.dart';
import '../../features/profile/presentation/screens/personal_info_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/settings_screen.dart';
import '../../features/rendez_vous/data/models/reservation_contexte.dart';
import '../../features/rendez_vous/presentation/screens/choix_creneau_screen.dart';
import '../../features/rendez_vous/presentation/screens/rendez_vous_confirmation_screen.dart';
import '../../features/rendez_vous/presentation/screens/rendez_vous_detail_screen.dart';
import '../../features/rendez_vous/data/models/rendez_vous_model.dart';
import '../../features/rendez_vous/presentation/screens/rendez_vous_screen.dart';
import '../../features/selection_univers/presentation/screens/selection_univers_screen.dart';
import '../services/app_preferences_service.dart';
import '../theme/universe_provider.dart';
import '../widgets/app_back_button.dart';
import '../widgets/app_button.dart';
import 'app_routes.dart';
import 'route_guard.dart';
import 'startup_splash.dart';
import '../../core/l10n/app_strings.dart';

/// Configuration GoRouter de l'application PsyAvocat.
///
/// - Créé UNE seule fois ; les redirections sont réévaluées quand le statut de
///   session ou l'univers change (pas à chaque reconstruction).
/// - Toutes les règles d'accès sont dans [resolveRedirect] (route_guard.dart).
/// - Écrans d'entrée (splash, connexion, statut du compte, choix de l'univers,
///   onglets) : fondu enchaîné. Écrans de détail empilés : transition native.
final appRouterProvider = Provider<GoRouter>((ref) {
  final prefs = ref.watch(appPreferencesServiceProvider);

  final refresh = ValueNotifier<int>(0);
  ref.listen(
    sessionControllerProvider.select((session) => session.status),
    (_, _) => refresh.value++,
  );
  ref.listen(currentUniverseProvider, (_, _) => refresh.value++);
  ref.listen(startupSplashDoneProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) => resolveRedirect(
      location: state.matchedLocation,
      session: ref.read(sessionControllerProvider).status,
      hasSeenOnboarding: prefs.hasSeenOnboarding(),
      universe: ref.read(currentUniverseProvider),
      splashDone: ref.read(startupSplashDoneProvider),
    ),
    errorBuilder: (context, state) => const _NotFoundScreen(),
    routes: [
      // --- Entrée et statut du compte (remplacés les uns par les autres) ---
      _fadeRoute(AppRoutes.splash, (_) => const SplashScreen()),
      _entreeRoute(AppRoutes.onboarding, (_) => const OnboardingScreen()),
      _entreeRoute(AppRoutes.login, (_) => const LoginScreen()),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, _) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (_, _) => const ForgotPasswordScreen(),
      ),
      _entreeRoute(AppRoutes.accessDenied, (_) => const AccessDeniedScreen()),
      _entreeRoute(AppRoutes.verifyEmail, (_) => const VerifyEmailScreen()),
      _entreeRoute(
        AppRoutes.completerProfil,
        (_) => const CompleterProfilScreen(),
      ),
      _entreeRoute(
        AppRoutes.universeSelection,
        (_) => const SelectionUniversScreen(),
      ),

      // --- Navigation principale : 5 onglets (navigation_destinations.dart) ---
      // Chaque onglet garde son état (scroll, sous-pages) d'un passage à l'autre.
      StatefulShellRoute.indexedStack(
        pageBuilder: (context, state, navigationShell) => _entreePage(
          state,
          MainNavigationShell(navigationShell: navigationShell),
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (_, _) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.articles,
                builder: (_, _) => const ContenusScreen(),
              ),
              GoRoute(
                path: AppRoutes.conseils,
                builder: (_, _) => const ContenusScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.professionnels,
                builder: (_, _) => const ProfessionnelsListScreen(),
                routes: [
                  GoRoute(
                    path: 'recherche',
                    builder: (_, _) => const RechercheScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.rendezVous,
                builder: (_, _) => const RendezVousScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profil,
                builder: (_, _) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // --- Écrans plein écran, au-dessus de la barre de navigation ---
      _fadeRoute(
        AppRoutes.orientationIntro,
        (_) => const OrientationIntroScreen(),
      ),
      _fadeRoute(
        AppRoutes.orientation,
        (_) => const OrientationQuestionnaireScreen(),
      ),
      _fadeRoute(
        AppRoutes.orientationResult,
        (_) => const OrientationResultScreen(),
      ),
      GoRoute(
        path: AppRoutes.dossiers,
        builder: (_, _) => const DossiersScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) =>
                DossierDetailScreen(dossierId: state.pathParameters['id']!),
            routes: [
              GoRoute(
                path: 'prise-en-charge',
                builder: (context, state) => DossierPriseEnChargeScreen(
                  dossierId: state.pathParameters['id']!,
                  depuisDossier: state.extra == true,
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.messagerie,
        builder: (_, _) => const MessagerieScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.messagerie}/:id',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          // Informations d'attente seulement : l'écran relit le correspondant
          // depuis la conversation (même affichage depuis une notification).
          return ConversationDetailScreen(
            conversationId: state.pathParameters['id']!,
            participantName: extra['name'] as String?,
            participantRole: extra['role'] as String?,
            participantPhotoUrl: extra['photoUrl'] as String?,
          );
        },
      ),
      GoRoute(
        path: '${AppRoutes.messagerie}/nouvelle/:destinataireId',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return ConversationDetailScreen(
            destinataireId: state.pathParameters['destinataireId']!,
            participantName: extra['name'] as String?,
            participantRole: extra['role'] as String?,
            participantPhotoUrl: extra['photoUrl'] as String?,
          );
        },
      ),
      GoRoute(
        path: '${AppRoutes.professionnels}/:id',
        builder: (context, state) => ProfessionnelDetailScreen(
          professionnelId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '${AppRoutes.professionnels}/:id/publications',
        builder: (context, state) => ProfessionnelPublicationsScreen(
          professionnelId: state.pathParameters['id']!,
          professionnelNom: state.extra is String
              ? state.extra as String
              : null,
        ),
      ),
      GoRoute(
        path: '${AppRoutes.professionnels}/:id/creneau',
        builder: (context, state) => ChoixCreneauScreen(
          professionnelId: state.pathParameters['id']!,
          contexte: state.extra is ReservationContexte
              ? state.extra as ReservationContexte
              : null,
        ),
      ),
      GoRoute(
        path: '/rendez-vous/detail/:id',
        builder: (context, state) => RendezVousDetailScreen(
          rendezVousId: state.pathParameters['id']!,
          initial: state.extra is RendezVous ? state.extra as RendezVous : null,
        ),
      ),
      GoRoute(
        path: AppRoutes.rendezVousConfirmation,
        builder: (context, state) => RendezVousConfirmationScreen(
          recap: state.extra is ReservationRecap
              ? state.extra as ReservationRecap
              : null,
        ),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (_, _) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/contenus/:id',
        builder: (context, state) =>
            ContenuDetailScreen(contenuId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.paiements,
        builder: (_, _) => const PaiementsScreen(),
      ),
      GoRoute(
        path: AppRoutes.informationsPersonnelles,
        builder: (_, _) => const PersonalInfoScreen(),
      ),
      GoRoute(
        path: AppRoutes.parametres,
        builder: (_, _) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.aideSupport,
        builder: (_, _) => const HelpSupportScreen(),
      ),
      GoRoute(
        path: AppRoutes.fichePatient,
        builder: (_, _) => const FichePatientScreen(),
      ),
    ],
  );
  // Bouton retour Android : sur la dernière page d'un écran (fiche ouverte depuis
  // une notification, onglet autre que l'accueil…), retour à l'accueil de
  // l'univers au lieu de quitter l'application.
  final retourSysteme =
      router.backButtonDispatcher.createChildBackButtonDispatcher()
        ..addCallback(() {
          final destination = destinationRetourSysteme(
            chemin: router.routerDelegate.currentConfiguration.uri.path,
            peutRevenir: router.canPop(),
          );
          if (destination == null) return SynchronousFuture(false);
          router.go(destination);
          return SynchronousFuture(true);
        });
  // La priorité ne peut être prise qu'une fois le Router affiché (il s'inscrit
  // alors auprès du répartiteur racine) : après la première image.
  var actif = true;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (actif) retourSysteme.takePriority();
  });
  ref.onDispose(() {
    actif = false;
    router.backButtonDispatcher.forget(retourSysteme);
  });

  ref.onDispose(router.dispose);
  return router;
});

/// Durée commune des fondus : courte, pour une navigation fluide.
const _fadeDuration = Duration(milliseconds: 250);

/// Pages qui peuvent suivre l'écran logo (connexion, accueil, choix de
/// l'univers…) : elles apparaissent en fondu une fois le logo effacé (voir
/// SplashScreen), avec un très léger zoom — transition douce, sans à-coup.
const _entreeDuration = Duration(milliseconds: 600);

GoRoute _entreeRoute(String path, Widget Function(GoRouterState) builder) {
  return GoRoute(
    path: path,
    pageBuilder: (context, state) => _entreePage(state, builder(state)),
  );
}

Page<void> _entreePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: _entreeDuration,
    reverseTransitionDuration: _fadeDuration,
    transitionsBuilder: (context, animation, _, child) {
      final entree = animation.drive(
        CurveTween(curve: const Interval(0.25, 1, curve: Curves.easeOutCubic)),
      );
      return FadeTransition(
        opacity: entree,
        child: ScaleTransition(
          scale: entree.drive(Tween(begin: 0.985, end: 1.0)),
          child: child,
        ),
      );
    },
  );
}

GoRoute _fadeRoute(String path, Widget Function(GoRouterState) builder) {
  return GoRoute(
    path: path,
    pageBuilder: (context, state) => _fadePage(state, builder(state)),
  );
}

Page<void> _fadePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: _fadeDuration,
    reverseTransitionDuration: _fadeDuration,
    transitionsBuilder: (context, animation, _, child) => FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: child,
    ),
  );
}

/// URL inconnue (lien profond obsolète…) : retour à l'accueil, que le guard
/// redirigera vers le bon écran selon la session.
class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.explore_off_outlined, size: 56),
              const SizedBox(height: 16),
              Text(tr('Page introuvable'), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              AppButton(
                text: tr("Retour à l'accueil"),
                onPressed: () => context.go(AppRoutes.home),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
