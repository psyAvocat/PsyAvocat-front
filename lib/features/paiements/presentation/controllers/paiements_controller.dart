import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/realtime/realtime_service.dart';
import '../../../../core/theme/universe_provider.dart';
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

/// Paiements de l'univers courant uniquement.
final paiementsUniversProvider = Provider<AsyncValue<List<PaiementModel>>>((
  ref,
) {
  final universe = ref.watch(currentUniverseProvider);
  return ref
      .watch(paiementsListProvider)
      .whenData((list) => list.where((p) => p.universe == universe).toList());
});
