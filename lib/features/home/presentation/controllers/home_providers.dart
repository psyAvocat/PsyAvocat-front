import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../orientation/data/models/questionnaire_model.dart';
import '../../../orientation/presentation/controllers/orientation_controller.dart';
import '../../../rendez_vous/data/models/rendez_vous_model.dart';
import '../../../rendez_vous/presentation/controllers/rendez_vous_controller.dart';

/// Statuts (déjà traduits par le repository) d'un rendez-vous encore à venir.
const _upcomingStatuses = {'Confirmé', 'En attente'};

/// Prochain rendez-vous de l'utilisateur (`null` s'il n'en a aucun à venir).
/// Dérivé de GET /api/rendez-vous : chargement et erreurs sont conservés.
final nextAppointmentProvider = Provider<AsyncValue<RendezVousItem?>>((ref) {
  return ref
      .watch(rendezVousListProvider)
      .whenData(
        (list) => list
            .where((rdv) => _upcomingStatuses.contains(rdv.status))
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
