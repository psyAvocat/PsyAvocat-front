/// Validateurs réutilisables pour les formulaires de l'application.
class Validators {
  Validators._();

  static String? required(String? value, [String message = 'Ce champ est requis']) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'L\'adresse email est requise';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Veuillez saisir une adresse email valide';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est requis';
    }
    if (value.length < 6) {
      return 'Le mot de passe doit comporter au moins 6 caractères';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // optionnel selon les cas
    }
    final phoneRegex = RegExp(r'^\+?[0-9\s\-]{8,15}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Numéro de téléphone invalide';
    }
    return null;
  }
}
