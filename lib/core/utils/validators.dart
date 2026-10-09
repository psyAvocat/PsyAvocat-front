/// Validateurs réutilisables pour les formulaires de l'application.
class Validators {
  Validators._();

  static String? required(
    String? value, [
    String message = 'Ce champ est requis',
  ]) {
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

  /// Message identique à `PhoneNumbers.MESSAGE_INVALIDE` (Spring Boot).
  static const phoneInvalidMessage =
      'Numéro de téléphone invalide : 8 à 15 chiffres, indicatif international '
      'facultatif (ex. +223 76 12 34 56).';

  /// Téléphone obligatoire d'un client, même règle que le backend (`PhoneNumbers`) :
  /// espaces, points, tirets et parenthèses ignorés, puis 8 à 15 chiffres
  /// précédés d'un `+` facultatif.
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le numéro de téléphone est requis';
    }
    final compact = value.replaceAll(RegExp(r'[\s.\-()]'), '');
    if (!RegExp(r'^\+?[0-9]{8,15}$').hasMatch(compact)) {
      return phoneInvalidMessage;
    }
    return null;
  }
}
