import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/profil_model.dart';
import '../../data/repositories/profil_repository.dart';

/// Provider du profil courant de l'utilisateur connecté.
final currentProfilProvider =
    AsyncNotifierProvider<ProfilNotifier, ProfilModel?>(
  ProfilNotifier.new,
);

/// Notifier gérant l'état du profil utilisateur.
class ProfilNotifier extends AsyncNotifier<ProfilModel?> {
  @override
  Future<ProfilModel?> build() async {
    return ref.read(profilRepositoryProvider).getCurrentProfile();
  }

  /// Met à jour les informations du profil utilisateur
  Future<bool> updateProfile({
    String? nom,
    String? prenom,
    String? telephone,
    String? ville,
  }) async {
    try {
      final updated = await ref.read(profilRepositoryProvider).updateProfile(
            nom: nom,
            prenom: prenom,
            telephone: telephone,
            ville: ville,
          );
      state = AsyncData(updated);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Crée un profil de type Patient
  Future<bool> createPatientProfile({
    required String nom,
    required String prenom,
    String? telephone,
    String? ville,
  }) async {
    try {
      final created = await ref.read(profilRepositoryProvider).createPatientProfile(
            nom: nom,
            prenom: prenom,
            telephone: telephone,
            ville: ville,
          );
      state = AsyncData(created);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Crée un profil de type Justiciable / Client juridique
  Future<bool> createJusticiableProfile({
    required String nom,
    required String prenom,
    String? telephone,
    String? ville,
  }) async {
    try {
      final created = await ref.read(profilRepositoryProvider).createJusticiableProfile(
            nom: nom,
            prenom: prenom,
            telephone: telephone,
            ville: ville,
          );
      state = AsyncData(created);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Rafraîchit les données du profil depuis le backend
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(profilRepositoryProvider).getCurrentProfile(),
    );
  }
}
