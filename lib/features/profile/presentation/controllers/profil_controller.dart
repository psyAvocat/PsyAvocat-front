import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/user_message.dart';
import '../../data/models/profil_model.dart';
import '../../data/repositories/profil_repository.dart';

/// Provider du profil courant de l'utilisateur connecté.
final currentProfilProvider =
    AsyncNotifierProvider<ProfilNotifier, ProfilModel?>(ProfilNotifier.new);

/// Notifier gérant l'état du profil utilisateur.
class ProfilNotifier extends AsyncNotifier<ProfilModel?> {
  @override
  Future<ProfilModel?> build() async {
    return ref.read(profilRepositoryProvider).getCurrentProfile();
  }

  /// Met à jour nom, prénom et téléphone (obligatoires côté backend).
  /// Renvoie `null` en cas de succès, sinon le message d'erreur à afficher.
  Future<String?> updateProfile({
    required String nom,
    required String prenom,
    required String telephone,
  }) async {
    try {
      final updated = await ref
          .read(profilRepositoryProvider)
          .updateProfile(nom: nom, prenom: prenom, telephone: telephone);
      state = AsyncData(updated);
      return null;
    } catch (error) {
      return userMessageFor(error);
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
