import '../../../../core/theme/app_universe.dart';
import '../../../../core/router/app_routes.dart';

/// Notification métier persistée (Spring Boot `/api/notifications`).
class NotificationItem {
  final String id;
  final String type;
  final String titre;
  final String contenu;
  final DateTime? dateEnvoi;
  final bool lu;
  final DateTime? dateLecture;

  /// AVOCAT, PSYCHOLOGUE ou null (transverse).
  final String? univers;

  /// RENDEZ_VOUS, CONVERSATION, ARTICLE, CONSEIL... : cible du lien profond.
  final String? ressourceType;
  final String? ressourceId;

  const NotificationItem({
    required this.id,
    required this.type,
    required this.titre,
    required this.contenu,
    required this.lu,
    this.dateEnvoi,
    this.dateLecture,
    this.univers,
    this.ressourceType,
    this.ressourceId,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id']?.toString() ?? '',
      type: json['type'] as String? ?? '',
      // Notifications anciennes sans titre : libellé générique, jamais inventé.
      titre: (json['titre'] as String?)?.trim().isNotEmpty == true
          ? json['titre'] as String
          : 'PsyAvocat',
      contenu: json['contenu'] as String? ?? '',
      dateEnvoi: DateTime.tryParse(json['dateEnvoi'] as String? ?? ''),
      lu: json['lu'] as bool? ?? false,
      dateLecture: DateTime.tryParse(json['dateLecture'] as String? ?? ''),
      univers: json['univers'] as String?,
      ressourceType: json['ressourceType'] as String?,
      ressourceId: json['ressourceId'] as String?,
    );
  }

  /// Univers de la ressource ciblée, ou null si la notification est transverse.
  AppUniverse? get universe {
    if (univers == 'AVOCAT') return AppUniverse.lawyer;
    if (univers == 'PSYCHOLOGUE') return AppUniverse.psychologist;
    return null;
  }

  bool get isRead => lu;
  String get message => contenu;
  DateTime? get date => dateEnvoi;

  String? get targetRoute {
    if (ressourceType == null || ressourceId == null) return null;
    switch (ressourceType!.toUpperCase()) {
      case 'RENDEZ_VOUS':
      case 'RDV':
        return AppRoutes.rendezVous;
      case 'CONVERSATION':
      case 'MESSAGE':
        return AppRoutes.conversation(ressourceId!);
      case 'ARTICLE':
      case 'CONSEIL':
      case 'CONTENU':
        return AppRoutes.contenu(ressourceId!);
      case 'DOSSIER':
        return AppRoutes.dossiers;
      default:
        return null;
    }
  }

  NotificationItem markedRead() => NotificationItem(
    id: id,
    type: type,
    titre: titre,
    contenu: contenu,
    lu: true,
    dateEnvoi: dateEnvoi,
    dateLecture: DateTime.now(),
    univers: univers,
    ressourceType: ressourceType,
    ressourceId: ressourceId,
  );
}

/// Alias rétrocompatible
typedef NotificationModel = NotificationItem;
