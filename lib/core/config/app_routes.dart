/// Chemins de navigation de l'application (un seul endroit à modifier).
class AppRoutes {
  AppRoutes._();

  // Démarrage et authentification
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const completeProfile = '/completer-profil';
  static const universeSelection = '/selection-univers';

  // Onglets de la barre de navigation (communs aux deux univers)
  static const home = '/home';
  static const publications = '/publications'; // Articles (Avocat) ou Conseils (Psychologue)
  static const professionals = '/professionnels'; // Avocats ou Psychologues
  static const appointments = '/rendez-vous';
  static const profile = '/profil';

  // Écrans de détail et d'action
  static String publication(String id) => '/publications/$id';
  static String professional(String id) => '/professionnels/$id';
  static String professionalAvailability(String id) => '/professionnels/$id/disponibilites';
  static const booking = '/rendez-vous/reserver';
  static String appointment(String id) => '/rendez-vous/$id';
  static String appointmentReschedule(String id) => '/rendez-vous/$id/modifier';
  static const notifications = '/notifications';
  static const conversations = '/messagerie';
  static String conversation(String id) => '/messagerie/$id';
  static const editProfile = '/profil/modifier';
  static const settings = '/parametres';
  static const changePassword = '/parametres/mot-de-passe';

  // Parcours Psychologue uniquement (questionnaire d'orientation)
  static const orientation = '/orientation';
}
