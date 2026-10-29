import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/realtime/realtime_service.dart';
import '../../../../core/theme/universe_provider.dart';
import '../../../rendez_vous/presentation/controllers/rendez_vous_controller.dart';
import '../../data/models/paiement_model.dart';
import '../../data/repositories/paiements_repository.dart';

final paiementsListProvider =
    AsyncNotifierProvider<PaiementsNotifier, List<PaiementModel>>(
      PaiementsNotifier.new,
    );

class PaiementsNotifier extends AsyncNotifier<List<PaiementModel>> {
  @override
  Future<List<PaiementModel>> build() async {
    // Réservation ou annulation : la liste suit l'état du backend.
    listenRealtime(ref, {RealtimeEventType.notification}, (event) {
      if (event.payload['ressourceType'] == 'RENDEZ_VOUS') unawaited(refresh());
    });
    return ref.read(paiementsRepositoryProvider).getMesPaiements();
  }

  Future<void> refresh() async {
    final result = await AsyncValue.guard(
      () => ref.read(paiementsRepositoryProvider).getMesPaiements(),
    );
    if (result.hasValue || !state.hasValue) state = result;
  }
}

/// Paiements strictement cloisonnés selon l'univers courant (Avocat vs Psychologue).
/// Croise aussi avec la liste des rendez-vous pour garantir le bon `typeProfessionnel`
/// même si le proxy Hibernate d'un ancien appel n'était pas déroulé.
final paiementsUniversProvider = Provider<AsyncValue<List<PaiementModel>>>((
  ref,
) {
  final universe = ref.watch(currentUniverseProvider);
  final rdvs = ref.watch(rendezVousControllerProvider).value;

  return ref.watch(paiementsListProvider).whenData((list) {
    final corriges = list.map((p) {
      if (rdvs != null && p.rendezVousId != null) {
        final match = rdvs.where((r) => r.id == p.rendezVousId).firstOrNull;
        if (match != null &&
            match.typeProfessionnel != null &&
            match.typeProfessionnel!.isNotEmpty) {
          return p.copyWith(typeProfessionnel: match.typeProfessionnel);
        }
      }
      return p;
    }).toList();

    return corriges.where((p) => p.universe == universe).toList();
  });
});
