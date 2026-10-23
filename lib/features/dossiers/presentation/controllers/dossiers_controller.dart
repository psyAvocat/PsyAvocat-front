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

/// Dossier confié à un avocat : la soumission acceptée porte ses honoraires.
typedef PriseEnCharge = ({DossierModel dossier, SoumissionModel soumission});

/// Dossiers du justiciable pris en charge par [avocatId] (honoraires proposés),
/// du plus récent au plus ancien : un rendez-vous peut être pris pour chacun.
/// Liste vide si les dossiers ne peuvent pas être lus.
final prisesEnChargeAvocatProvider = FutureProvider.autoDispose
    .family<List<PriseEnCharge>, String>((ref, avocatId) async {
      final List<DossierModel> dossiers;
      try {
        dossiers = await ref.watch(dossiersListProvider.future);
      } catch (_) {
        return const [];
      }
      final prises = <PriseEnCharge>[
        for (final dossier in dossiers)
          for (final s in dossier.soumissions)
            if (s.avocatId == avocatId &&
                s.estAcceptee &&
                s.tarifPropose != null)
              (dossier: dossier, soumission: s),
      ];
      prises.sort((a, b) {
        final da = a.soumission.dateReponse;
        final db = b.soumission.dateReponse;
        if (da == null) return db == null ? 0 : 1;
        if (db == null) return -1;
        return db.compareTo(da);
      });
      return prises;
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
