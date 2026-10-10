import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/dossier_model.dart';
import '../../data/repositories/dossier_repository.dart';

/// Provider pour la liste des dossiers de l'utilisateur
final dossiersListProvider =
    AsyncNotifierProvider<DossiersNotifier, List<DossierModel>>(
      DossiersNotifier.new,
    );

class DossiersNotifier extends AsyncNotifier<List<DossierModel>> {
  @override
  Future<List<DossierModel>> build() async {
    return ref.read(dossierRepositoryProvider).getMyDossiers();
  }

  Future<bool> createDossier({
    required String titre,
    required String description,
    required String domaine,
  }) async {
    try {
      final newDossier = await ref
          .read(dossierRepositoryProvider)
          .createDossier(
            titre: titre,
            description: description,
            domaine: domaine,
          );
      final current = state.value ?? [];
      state = AsyncData([newDossier, ...current]);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(dossierRepositoryProvider).getMyDossiers(),
    );
  }
}
