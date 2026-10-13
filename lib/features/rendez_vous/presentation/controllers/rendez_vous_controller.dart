import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/realtime/realtime_service.dart';
import '../../../../core/theme/universe_provider.dart';
import '../../../../shared/enums/appointment_status.dart';
import '../../../auth/presentation/controllers/session_controller.dart';
import '../../data/models/rendez_vous_model.dart';
import '../../data/models/reservation_contexte.dart';
import '../../data/repositories/rendez_vous_repository.dart';

/// Rendez-vous du compte. Aucune donnée n'est créée localement : chaque
/// action passe par le backend, puis la liste est rechargée.
class RendezVousController extends AsyncNotifier<List<RendezVous>> {
  @override
  Future<List<RendezVous>> build() async {
    // Mode invité : aucun rendez-vous, aucun appel protégé. Rechargé à la connexion.
    if (ref.watch(signedInAccountProvider) == null) return const [];
    listenRealtime(ref, {RealtimeEventType.notification}, (event) {
      if (event.payload['ressourceType'] == 'RENDEZ_VOUS') reload();
    });
    return ref.read(rendezVousRepositoryProvider).getMesRendezVous();
  }

  Future<void> reload() async {
    final result = await AsyncValue.guard(
      () => ref.read(rendezVousRepositoryProvider).getMesRendezVous(),
    );
    if (result.hasValue || !state.hasValue) state = result;
  }

  /// Réservation (psychologue ou avocat via dossier accepté) après simulation
  /// de l'acompte. Lève une ConflictException si le créneau vient d'être pris.
  Future<RendezVous> reserver(ReservationRecap recap) async {
    final repo = ref.read(rendezVousRepositoryProvider);
    final contexte = recap.contexte;
    final rdv = contexte.viaDossier
        ? await repo.reserverAvocat(
            soumissionId: contexte.soumissionId!,
            disponibiliteId: recap.creneau.id,
            mode: recap.mode,
          )
        : await repo.reserverPsychologue(
            psychologueId: contexte.professionnelId,
            disponibiliteId: recap.creneau.id,
            mode: recap.mode,
            montantTotal: contexte.montantTotal,
            motif: recap.motif,
          );
    await reload();
    return rdv;
  }

  Future<RendezVous> modifierCreneau({
    required String id,
    required String disponibiliteId,
  }) async {
    final rdv = await ref
        .read(rendezVousRepositoryProvider)
        .modifierCreneau(id: id, disponibiliteId: disponibiliteId);
    ref.invalidate(rendezVousDetailProvider(id));
    await reload();
    return rdv;
  }

  Future<void> annuler(String id) async {
    await ref.read(rendezVousRepositoryProvider).annuler(id);
    ref.invalidate(rendezVousDetailProvider(id));
    await reload();
  }
}

final rendezVousControllerProvider =
    AsyncNotifierProvider<RendezVousController, List<RendezVous>>(
      RendezVousController.new,
    );

/// Rendez-vous de l'univers courant, regroupés par onglet.
final rendezVousByPhaseProvider = Provider.autoDispose
    .family<AsyncValue<List<RendezVous>>, AppointmentPhase>((ref, phase) {
      final universe = ref.watch(currentUniverseProvider);
      final now = DateTime.now();
      return ref.watch(rendezVousControllerProvider).whenData((list) {
        final filtered =
            list
                .where((r) => r.universe == universe && r.phaseAt(now) == phase)
                .toList()
              ..sort(
                (a, b) => phase == AppointmentPhase.passe
                    ? b.dateHeure.compareTo(a.dateHeure)
                    : a.dateHeure.compareTo(b.dateHeure),
              );
        return filtered;
      });
    });

/// Prochain rendez-vous de l'univers courant (null s'il n'y en a aucun).
final nextAppointmentProvider = Provider.autoDispose<AsyncValue<RendezVous?>>((
  ref,
) {
  return ref
      .watch(rendezVousByPhaseProvider(AppointmentPhase.aVenir))
      .whenData((list) => list.firstOrNull);
});

final rendezVousDetailProvider = FutureProvider.autoDispose
    .family<RendezVous, String>((ref, id) {
      return ref.read(rendezVousRepositoryProvider).getRendezVous(id);
    });
