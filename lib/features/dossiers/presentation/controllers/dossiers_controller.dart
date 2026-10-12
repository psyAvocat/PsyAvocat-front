import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/realtime/realtime_service.dart';
import '../../data/models/dossier_model.dart';
import '../../data/repositories/dossier_repository.dart';

/// Dossiers du justiciable, rechargés à chaque notification (réponse d'un avocat,
/// prise en charge) pour que le statut affiché reste celui du backend.
final dossiersListProvider =
    AsyncNotifierProvider<DossiersNotifier, List<DossierModel>>(
      DossiersNotifier.new,
    );

/// Dossier consulté : relu dans la liste à jour (statuts temps réel), ou
/// chargé directement s'il n'y figure pas (lien depuis une notification).
final dossierDetailProvider = FutureProvider.autoDispose
    .family<DossierModel, String>((ref, id) async {
      final dossiers = await ref.watch(dossiersListProvider.future);
      for (final dossier in dossiers) {
        if (dossier.id == id) return dossier;
      }
      return ref.read(dossierRepositoryProvider).getDossierById(id);
    });

class DossiersNotifier extends AsyncNotifier<List<DossierModel>> {
  @override
  Future<List<DossierModel>> build() async {
    listenRealtime(ref, {RealtimeEventType.notification}, (event) {
      final ressource = event.payload['ressourceType'];
      if (ressource == 'DOSSIER' || ressource == 'SOUMISSION') {
        unawaited(refresh());
      }
    });
    return ref.read(dossierRepositoryProvider).getMyDossiers();
  }

  Future<void> refresh() async {
    final result = await AsyncValue.guard(
      () => ref.read(dossierRepositoryProvider).getMyDossiers(),
    );
    // Une erreur de rafraîchissement n'efface pas une liste déjà affichée.
    if (result.hasValue || !state.hasValue) state = result;
  }
}
