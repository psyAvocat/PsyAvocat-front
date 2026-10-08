import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_universe.dart';
import '../../../../core/theme/universe_provider.dart';
import '../../../auth/data/models/current_user.dart';
import '../../../auth/data/repositories/session_repository.dart';
import '../../../auth/presentation/controllers/pending_profile_controller.dart';
import '../../../profile/data/repositories/profil_repository.dart';

/// Choix de l'univers Avocat / Psychologue.
///
/// Ce n'est pas qu'un changement de couleur :
/// 1. si l'utilisateur n'a pas encore de profil métier (juste après l'inscription),
///    on le crée dans le backend : patient (Psychologue) ou justiciable (Avocat) ;
/// 2. on enregistre l'univers (thème + données chargées ensuite).
class UniverseSelectionController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  /// Renvoie `true` si tout s'est bien passé (sinon : voir `state.error`).
  Future<bool> select(AppUniverse universe) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _createBusinessProfileIfNeeded(universe);
      await ref.read(currentUniverseProvider.notifier).setUniverse(universe);
    });
    return !state.hasError;
  }

  Future<void> _createBusinessProfileIfNeeded(AppUniverse universe) async {
    final user = await ref.read(currentUserProvider.future);
    if (user.hasMetierProfile) return;

    final identity = _identityFor(user);
    final profilRepository = ref.read(profilRepositoryProvider);

    if (universe.isPsychologist) {
      await profilRepository.createClientProfile(
        nom: identity.nom,
        prenom: identity.prenom,
        telephone: identity.telephone,
      );
    } else {
      await profilRepository.createClientProfile(
        nom: identity.nom,
        prenom: identity.prenom,
        telephone: identity.telephone,
      );
    }

    ref.read(pendingProfileProvider.notifier).clear();
    ref.invalidate(currentUserProvider);
  }

  /// Identité saisie à l'inscription, ou à défaut celle connue du backend.
  PendingProfile _identityFor(CurrentUser user) {
    final pending = ref.read(pendingProfileProvider);
    if (pending != null) return pending;

    final prenom = user.prenom?.trim() ?? '';
    final nom = user.nom?.trim() ?? '';
    if (prenom.isNotEmpty && nom.isNotEmpty) {
      return PendingProfile(prenom: prenom, nom: nom);
    }

    throw const AppException(
      'Votre profil ne peut pas être créé : prénom et nom inconnus. '
      'Reconnectez-vous ou contactez le support PsyAvocat.',
    );
  }
}

final universeSelectionControllerProvider =
    NotifierProvider<UniverseSelectionController, AsyncValue<void>>(
      UniverseSelectionController.new,
    );
