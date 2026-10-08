import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../orientation/data/models/questionnaire_model.dart';
import '../../../orientation/presentation/controllers/orientation_controller.dart';
import '../../../rendez_vous/data/models/rendez_vous_model.dart';
import '../../../rendez_vous/presentation/controllers/rendez_vous_controller.dart';
import '../../../../shared/enums/appointment_status.dart';

/// Prochain rendez-vous de l'utilisateur (`null` s'il n'en a aucun à venir).
/// Dérivé de GET /api/rendez-vous : chargement et erreurs sont conservés.
final nextAppointmentProvider = Provider<AsyncValue<RendezVous?>>((ref) {
  return ref
      .watch(rendezVousControllerProvider)
      .whenData(
        (list) => list
            .where((rdv) => rdv.phaseAt(DateTime.now()) == AppointmentPhase.aVenir)
            .firstOrNull,
      );
});

/// Résultat d'orientation le plus récent (`null` si jamais fait).
/// Dérivé de GET /api/orientation/mes-resultats.
final latestOrientationProvider =
    Provider<AsyncValue<ResultatOrientationModel?>>((ref) {
      return ref
          .watch(mesResultatsProvider)
          .whenData((results) => results.firstOrNull);
    });
