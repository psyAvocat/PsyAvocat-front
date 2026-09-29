import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/rendez_vous_model.dart';
import '../../data/repositories/rendez_vous_repository.dart';

/// AsyncNotifier pour la liste des rendez-vous.
/// Charge depuis l'API backend (GET /api/rendez-vous) avec états loading/error/data.
class RendezVousNotifier extends AsyncNotifier<List<RendezVousItem>> {
  @override
  Future<List<RendezVousItem>> build() async {
    return ref.read(rendezVousRepositoryProvider).getMyRendezVous();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(rendezVousRepositoryProvider).getMyRendezVous(),
    );
  }

  /// Ajoute un rendez-vous localement + synchronise avec l'API
  Future<void> addRendezVous({
    required String proId,
    required String proName,
    required String proRole,
    required String specialty,
    required String day,
    required String month,
    required String year,
    required String time,
    required String mode,
    required int montantTotal,
    String? motif,
    String? disponibiliteId,
  }) async {
    final acompte = (montantTotal * 0.20).round();
    final newItem = RendezVousItem(
      id: 'rdv-${DateTime.now().millisecondsSinceEpoch}',
      day: day,
      month: month,
      year: year,
      time: time,
      proId: proId,
      proName: proName,
      proRole: proRole,
      specialty: specialty,
      mode: mode,
      status: 'Confirmé',
      montantTotal: montantTotal,
      montantAcompte: acompte,
      motif: motif,
    );

    final current = state.value ?? [];
    state = AsyncData([newItem, ...current]);

    // Synchro API en arrière-plan si on a une disponibiliteId
    if (disponibiliteId != null && disponibiliteId.isNotEmpty) {
      ref.read(rendezVousRepositoryProvider).createRendezVousDirect(
        proId: proId,
        isAvocat: proRole.toLowerCase().contains('avocat'),
        disponibiliteId: disponibiliteId,
        mode: mode,
        montantTotal: montantTotal.toDouble(),
        motif: motif,
      ).then((created) {
        final updated = (state.value ?? [])
            .map((r) => r.id == newItem.id ? created : r)
            .toList();
        state = AsyncData(updated);
      }).catchError((_) {});
    }
  }

  /// Annule un rendez-vous — mise à jour optimiste + appel API
  void cancelRendezVous(String id) {
    final current = state.value ?? [];
    state = AsyncData(
      current.map((r) {
        if (r.id == id) {
          return RendezVousItem(
            id: r.id, day: r.day, month: r.month, year: r.year,
            time: r.time, proId: r.proId, proName: r.proName,
            proRole: r.proRole, specialty: r.specialty, mode: r.mode,
            status: 'Annulé',
            montantTotal: r.montantTotal, montantAcompte: r.montantAcompte,
            motif: r.motif,
          );
        }
        return r;
      }).toList(),
    );
    ref.read(rendezVousRepositoryProvider).annulerRendezVous(id).catchError((_) {});
  }
}

final rendezVousListProvider =
    AsyncNotifierProvider<RendezVousNotifier, List<RendezVousItem>>(
  RendezVousNotifier.new,
);
