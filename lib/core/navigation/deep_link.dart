import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../router/app_routes.dart';
import '../theme/app_universe.dart';

/// Cible d'un lien profond (notification push ou notification in-app).
///
/// Construite uniquement à partir des clés envoyées par Spring Boot :
/// `univers`, `ressourceType`, `ressourceId`.
class DeepLinkTarget {
  /// Univers de la ressource ; null si elle est commune aux deux univers.
  final AppUniverse? universe;
  final String? ressourceType;
  final String? ressourceId;

  /// Type de notification (ex. DOSSIER_ACCEPTE) : affine l'écran ouvert.
  final String? type;

  const DeepLinkTarget({
    this.universe,
    this.ressourceType,
    this.ressourceId,
    this.type,
  });

  factory DeepLinkTarget.fromData(Map<String, dynamic> data) {
    return DeepLinkTarget(
      universe: universeFromApi(data['univers'] as String?),
      ressourceType: data['ressourceType'] as String?,
      ressourceId: data['ressourceId'] as String?,
      type: data['type'] as String?,
    );
  }

  static AppUniverse? universeFromApi(String? value) {
    if (value == 'AVOCAT') return AppUniverse.lawyer;
    if (value == 'PSYCHOLOGUE') return AppUniverse.psychologist;
    return null;
  }

  /// Écran à ouvrir. Sans ressource exploitable : la liste des notifications.
  String get location {
    final id = ressourceId;
    if (id == null || id.isEmpty) return AppRoutes.notifications;
    switch (ressourceType) {
      case 'RENDEZ_VOUS':
        // Détail du rendez-vous (et accès à la salle s'il est en visio).
        return AppRoutes.rendezVousDetail(id);
      case 'CONVERSATION':
        return AppRoutes.conversation(id);
      case 'ARTICLE':
      case 'CONSEIL':
      case 'CONTENU':
        return AppRoutes.contenu(id);
      case 'PROFESSIONNEL':
        return AppRoutes.professionnel(id);
      case 'DOSSIER':
        // Dossier accepté : l'avocat, ses honoraires et la prise de rendez-vous.
        return type == 'DOSSIER_ACCEPTE'
            ? AppRoutes.dossierPriseEnCharge(id)
            : AppRoutes.dossier(id);
      case 'SOUMISSION':
        // Dossiers juridiques (univers Avocat) : la liste affiche le suivi des réponses.
        return AppRoutes.dossiers;
      default:
        return AppRoutes.notifications;
    }
  }

  /// Vrai si l'ouverture impose de changer d'univers (confirmation requise).
  bool requiresSwitchFrom(AppUniverse current) =>
      universe != null && !current.isNeutral && universe != current;
}

/// Lien profond en attente : déposé par le service push, consommé par le
/// shell de navigation (qui gère la confirmation de changement d'univers).
class PendingDeepLinkNotifier extends Notifier<DeepLinkTarget?> {
  @override
  DeepLinkTarget? build() => null;

  void push(DeepLinkTarget target) => state = target;

  /// Récupère le lien et le retire (consommé une seule fois).
  DeepLinkTarget? take() {
    final target = state;
    state = null;
    return target;
  }
}

final pendingDeepLinkProvider =
    NotifierProvider<PendingDeepLinkNotifier, DeepLinkTarget?>(
      PendingDeepLinkNotifier.new,
    );
