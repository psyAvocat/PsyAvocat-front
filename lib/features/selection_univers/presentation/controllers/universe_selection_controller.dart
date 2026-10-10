import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_universe.dart';
import '../../../../core/theme/universe_provider.dart';

/// Choix de l'univers Avocat / Psychologue.
///
/// Le profil client est unique et déjà créé (à l'inscription ou sur l'écran
/// « Compléter mon profil ») : choisir l'univers ne fait qu'enregistrer le
/// contexte affiché (thème + données chargées ensuite).
class UniverseSelectionController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  /// Renvoie `true` si tout s'est bien passé (sinon : voir `state.error`).
  Future<bool> select(AppUniverse universe) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(currentUniverseProvider.notifier).setUniverse(universe),
    );
    return !state.hasError;
  }
}

final universeSelectionControllerProvider =
    NotifierProvider<UniverseSelectionController, AsyncValue<void>>(
      UniverseSelectionController.new,
    );
