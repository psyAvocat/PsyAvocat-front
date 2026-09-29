/// Modèles de données pour la messagerie instantanée PsyAvocat
class ConversationModel {
  final String id;
  final String participantNom;
  final String participantPrenom;
  final String participantRole; // AVOCAT | PSYCHOLOGUE
  final String? dernierMessage;
  final DateTime? dernierMessageDate;
  final int messagesNonLus;

  const ConversationModel({
    required this.id,
    required this.participantNom,
    required this.participantPrenom,
    required this.participantRole,
    this.dernierMessage,
    this.dernierMessageDate,
    this.messagesNonLus = 0,
  });

  String get displayName {
    final prefix = participantRole == 'AVOCAT' ? 'Maître' : 'Dr.';
    return '$prefix $participantPrenom $participantNom'.trim();
  }

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] as String? ?? '',
      participantNom: json['participantNom'] as String? ?? '',
      participantPrenom: json['participantPrenom'] as String? ?? '',
      participantRole: json['participantRole'] as String? ?? 'AVOCAT',
      dernierMessage: json['dernierMessage'] as String?,
      dernierMessageDate: json['dernierMessageDate'] != null
          ? DateTime.tryParse(json['dernierMessageDate'] as String)
          : null,
      messagesNonLus: (json['messagesNonLus'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participantNom': participantNom,
      'participantPrenom': participantPrenom,
      'participantRole': participantRole,
      'dernierMessage': dernierMessage,
      'dernierMessageDate': dernierMessageDate?.toIso8601String(),
      'messagesNonLus': messagesNonLus,
    };
  }
}

class MessageModel {
  final String id;
  final String contenu;
  final DateTime dateEnvoi;
  final bool isFromMe;
  final String expediteurNom;

  const MessageModel({
    required this.id,
    required this.contenu,
    required this.dateEnvoi,
    required this.isFromMe,
    required this.expediteurNom,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json, String myUid) {
    return MessageModel(
      id: json['id'] as String? ?? '',
      contenu: json['contenu'] as String? ?? '',
      dateEnvoi: DateTime.tryParse(json['dateEnvoi'] as String? ?? '') ?? DateTime.now(),
      isFromMe: (json['expediteurUid'] as String?) == myUid,
      expediteurNom: json['expediteurNom'] as String? ?? 'Moi',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contenu': contenu,
      'dateEnvoi': dateEnvoi.toIso8601String(),
      'isFromMe': isFromMe,
      'expediteurNom': expediteurNom,
    };
  }
}
