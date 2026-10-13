import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/app_preferences_service.dart';

/// Informations saisies à l'inscription pour le profil client.
class PendingRegistration {
  final String nom;
  final String prenom;
  final String telephone;

  const PendingRegistration({
    required this.nom,
    required this.prenom,
    required this.telephone,
  });

  Map<String, String> toJson() => {
    'nom': nom,
    'prenom': prenom,
    'telephone': telephone,
  };

  static PendingRegistration? tryParse(String? raw) {
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return PendingRegistration(
        nom: json['nom'] as String,
        prenom: json['prenom'] as String,
        telephone: json['telephone'] as String,
      );
    } catch (_) {
      return null;
    }
  }
}

/// Inscription en attente de confirmation par le serveur, gardée sur l'appareil.
///
/// Si la création du profil échoue (serveur injoignable…), le compte Firebase
/// existe déjà : le profil est alors créé automatiquement à la connexion
/// suivante avec ces informations, sans les redemander à l'utilisateur.
/// Effacée dès que le serveur a confirmé (ou refusé) le profil.
class PendingRegistrationStore {
  final SharedPreferences _prefs;

  PendingRegistrationStore(this._prefs);

  static String _key(String firebaseUid) => 'pending_registration_$firebaseUid';

  PendingRegistration? read(String firebaseUid) =>
      PendingRegistration.tryParse(_prefs.getString(_key(firebaseUid)));

  Future<void> save(String firebaseUid, PendingRegistration registration) =>
      _prefs.setString(_key(firebaseUid), jsonEncode(registration.toJson()));

  Future<void> clear(String firebaseUid) => _prefs.remove(_key(firebaseUid));
}

final pendingRegistrationStoreProvider = Provider<PendingRegistrationStore>((
  ref,
) {
  return PendingRegistrationStore(ref.watch(sharedPreferencesProvider));
});
