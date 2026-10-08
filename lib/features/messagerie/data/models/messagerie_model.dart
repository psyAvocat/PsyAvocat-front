import '../../../../core/theme/app_universe.dart';

/// Message d'une conversation (MessageResponseDTO).
class Message {
  final String id;
  final String conversationId;
  final String contenu;
  final DateTime? dateEnvoi;
  final String? expediteurId;
  final bool lu;

  const Message({
    required this.id,
    required this.conversationId,
    required this.contenu,
    required this.lu,
    this.dateEnvoi,
    this.expediteurId,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id']?.toString() ?? '',
      conversationId: json['conversationId']?.toString() ?? '',
      contenu: json['contenu'] as String? ?? '',
      dateEnvoi: DateTime.tryParse(json['dateEnvoi'] as String? ?? ''),
      expediteurId: json['expediteurId'] as String?,
      lu: json['lu'] as bool? ?? false,
    );
  }
}

/// Conversation avec un professionnel (ConversationResponseDTO).
class Conversation {
  final String id;
  final String? correspondantId;
  final String correspondantNom;
  final String correspondantPrenom;

  /// AVOCAT, PSYCHOLOGUE ou CLIENT.
  final String? correspondantType;
  final String? correspondantPhotoUrl;
  final Message? dernierMessage;
  final int messagesNonLus;

  const Conversation({
    required this.id,
    required this.correspondantNom,
    required this.correspondantPrenom,
    required this.messagesNonLus,
    this.correspondantId,
    this.correspondantType,
    this.correspondantPhotoUrl,
    this.dernierMessage,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    final dernier = json['dernierMessage'];
    return Conversation(
      id: json['id']?.toString() ?? '',
      correspondantId: json['correspondantId'] as String?,
      correspondantNom: json['correspondantNom'] as String? ?? '',
      correspondantPrenom: json['correspondantPrenom'] as String? ?? '',
      correspondantType: json['correspondantType'] as String?,
      correspondantPhotoUrl: json['correspondantPhotoUrl'] as String?,
      dernierMessage: dernier is Map<String, dynamic> ? Message.fromJson(dernier) : null,
      messagesNonLus: (json['messagesNonLus'] as num?)?.toInt() ?? 0,
    );
  }

  /// Univers de la conversation (celui du professionnel), ou null si inconnu.
  AppUniverse? get universe {
    if (correspondantType == 'AVOCAT') return AppUniverse.lawyer;
    if (correspondantType == 'PSYCHOLOGUE') return AppUniverse.psychologist;
    return null;
  }

  String get correspondantDisplayName {
    final nom = '$correspondantPrenom $correspondantNom'.trim();
    if (correspondantType == 'AVOCAT') return 'Me $nom';
    if (correspondantType == 'PSYCHOLOGUE') return 'Dr $nom';
    return nom;
  }
}
