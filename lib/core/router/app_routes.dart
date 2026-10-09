/// Chemins de toutes les routes de l'application, en un seul endroit.
///
/// Les écrans naviguent avec ces constantes (`context.go(AppRoutes.home)`)
/// plutôt qu'avec des chaînes écrites à la main.
class AppRoutes {
  AppRoutes._();

  // Parcours d'entrée
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const accessDenied = '/acces-refuse';
  static const completeProfile = '/completer-profil';
  static const verifyEmail = '/verification-email';
  static const universeSelection = '/selection-univers';

  // Onglets de la barre de navigation
  static const home = '/home';
  static const articles = '/articles';
  static const conseils = '/conseils';
  static const professionnels = '/professionnels';
  static const professionnelsRecherche = '/professionnels/recherche';
  static const rendezVous = '/rendez-vous';
  static const profil = '/profil';

  // Orientation (univers Psychologue uniquement)
  static const orientation = '/orientation';
  static const orientationIntro = '/orientation/intro';
  static const orientationResult = '/orientation/resultat';

  // Autres écrans
  static const notifications = '/notifications';
  static const dossiers = '/dossiers';
  static const messagerie = '/messagerie';
  static const rendezVousConfirmation = '/rendez-vous/confirmation';
  static const suiviPsychologique = '/suivi-psychologique';
  static const paiements = '/paiements';

  /// Détail d'un article ou d'un conseil.
  static String contenu(String id) => '/contenus/$id';

  /// Discussion de la messagerie.
  static String conversation(String id) => '$messagerie/$id';

  /// Fiche d'un professionnel.
  static String professionnel(String id) => '$professionnels/$id';

  /// Choix du créneau chez un professionnel.
  static String choixCreneau(String id) => '$professionnels/$id/creneau';

  /// Routes accessibles sans être connecté.
  static const publicRoutes = {onboarding, login, register, forgotPassword};

  /// Écrans d'entrée et de session : quittés pour l'accueil une fois autorisé.
  static const entryRoutes = {
    splash,
    ...publicRoutes,
    accessDenied,
    completeProfile,
    verifyEmail,
  };
}
