/// Référentiel des endpoints de l'API REST Spring Boot PsyAvocat.
class ApiEndpoints {
  ApiEndpoints._();

  // Santé & Diagnostic
  static const String health = '/health';

  // Utilisateurs & Authentification
  static const String me = '/me';
  static const String users = '/utilisateurs';
  static const String profile = '/utilisateurs/profil';

  // Professionnels (Avocats & Psychologues)
  static const String professionnels = '/professionnels';
  static const String avocats = '/avocats';
  static const String psychologues = '/psychologues';
  static const String specialites = '/specialites';
  static const String categoriesBesoin = '/categories-besoin';

  // Dossiers juridiques
  static const String dossiers = '/dossiers';
  static const String soumissions = '/soumissions-dossiers';

  // Disponibilités & Rendez-vous
  static const String disponibilites = '/disponibilites';
  static const String rendezVous = '/rendez-vous';

  // Suivi psychologique
  static const String fichesPatients = '/fiches-patients';
  static const String seances = '/seances';

  // Orientation
  static const String questionnaires = '/questionnaires';
  static const String resultatsOrientation = '/resultats-orientation';

  // Communication & Messagerie
  static const String conversations = '/conversations';
  static const String messages = '/messages';
  static const String notifications = '/notifications';
  static const String signalements = '/signalements';

  // Paiements & Abonnements
  static const String paiements = '/paiements';
  static const String forfaits = '/forfaits';
  static const String abonnements = '/abonnements';

  // Contenus & Activités
  static const String contenus = '/contenus';
  static const String activites = '/activites';
}
