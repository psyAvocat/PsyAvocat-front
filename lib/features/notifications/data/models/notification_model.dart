/// Modèle pour une notification dans PsyAvocat
class NotificationModel {
  final String id;
  final String titre;
  final String message;
  final DateTime date;
  final String type; // RDV | DOSSIER | MESSAGE | SYSTEME
  final bool isRead;
  final String? targetRoute;

  const NotificationModel({
    required this.id,
    required this.titre,
    required this.message,
    required this.date,
    required this.type,
    this.isRead = false,
    this.targetRoute,
  });

  NotificationModel copyWith({
    String? id,
    String? titre,
    String? message,
    DateTime? date,
    String? type,
    bool? isRead,
    String? targetRoute,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      titre: titre ?? this.titre,
      message: message ?? this.message,
      date: date ?? this.date,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      targetRoute: targetRoute ?? this.targetRoute,
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final rawMessage = json['message'] as String? ?? json['contenu'] as String? ?? '';
    final rawTitre = json['titre'] as String? ?? (json['type'] != null ? 'Notification ${json['type']}' : 'Notification');
    final rawDate = json['date'] as String? ?? json['dateEnvoi'] as String?;
    final parsedDate = rawDate != null ? (DateTime.tryParse(rawDate) ?? DateTime.now()) : DateTime.now();
    final readStatus = json['isRead'] as bool? ?? json['lu'] as bool? ?? false;

    // Détermination de la route cible selon les données API ou le type
    String? route = json['targetRoute'] as String?;
    if (route == null || route.isEmpty) {
      final t = (json['type'] as String? ?? '').toUpperCase();
      if (t == 'RDV' || t == 'RENDEZ_VOUS') {
        route = '/rendez-vous';
      } else if (t == 'DOSSIER') {
        route = '/dossiers';
      } else if (t == 'MESSAGE' || t == 'CONVERSATION') {
        route = '/messagerie';
      } else if (t == 'CONTENU' || t == 'ARTICLE') {
        route = '/contenus';
      }
    }

    return NotificationModel(
      id: json['id']?.toString() ?? '',
      titre: rawTitre,
      message: rawMessage,
      date: parsedDate,
      type: json['type'] as String? ?? 'SYSTEME',
      isRead: readStatus,
      targetRoute: route,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titre': titre,
      'message': message,
      'date': date.toIso8601String(),
      'type': type,
      'isRead': isRead,
      if (targetRoute != null) 'targetRoute': targetRoute,
    };
  }
}
