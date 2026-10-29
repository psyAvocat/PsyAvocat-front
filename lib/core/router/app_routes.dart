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

  /// Détail d'un rendez-vous (page plein écran, au-dessus de la barre de navigation).
  static String rendezVousDetail(String id) => '/rendez-vous/detail/$id';
  static const paiements = '/paiements';

  // Sous-pages du profil
  static const informationsPersonnelles = '/profil/informations';
  static const parametres = '/profil/parametres';
  static const aideSupport = '/profil/aide';

  /// Fiche patient (univers Psychologue uniquement).
  static const fichePatient = '/profil/fiche-patient';

  /// Détail d'un article ou d'un conseil.
  static String contenu(String id) => '/contenus/$id';

  /// Consultation d'un dossier juridique.
  static String dossier(String id) => '$dossiers/$id';

  /// Dossier pris en charge : avocat, réponse, honoraires et prise de rendez-vous.
  static String dossierPriseEnCharge(String id) =>
      '$dossiers/$id/prise-en-charge';

  /// Discussion de la messagerie.
  static String conversation(String id) => '$messagerie/$id';

  /// Brouillon de discussion avec un professionnel : créée au premier message.
  static String nouvelleConversation(String destinataireId) =>
      '$messagerie/nouvelle/$destinataireId';

  /// Fiche d'un professionnel.
  static String professionnel(String id) => '$professionnels/$id';

  /// Articles ou conseils publiés par un professionnel.
  static String publicationsProfessionnel(String id) =>
      '$professionnels/$id/publications';

  /// Choix du créneau chez un professionnel.
  static String choixCreneau(String id) => '$professionnels/$id/creneau';

  /// Pages racines des onglets : on les rejoint avec `go` (jamais empilées).
  static const ongletsPrincipaux = {
    home,
    articles,
    conseils,
    professionnels,
    rendezVous,
    profil,
  };

  /// Connexion, inscription et mot de passe oublié : toujours accessibles.
  static const authRoutes = {login, register, forgotPassword};

  /// Profil à compléter (prénom, nom, téléphone) après une première connexion Google.
  static const completerProfil = '/completer-profil';

  /// Écrans d'entrée et de session : quittés pour l'accueil une fois autorisé.
  static const entryRoutes = {
    splash,
    onboarding,
    ...authRoutes,
    accessDenied,
    verifyEmail,
    completerProfil,
  };
}
