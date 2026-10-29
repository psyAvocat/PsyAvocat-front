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

/// Fil d'une conversation : chaque message une seule fois (par identifiant),
/// du plus ancien au plus récent. Un même message peut arriver par plusieurs
/// chemins (réponse à l'envoi, temps réel, relecture) sans jamais être doublé.
List<Message> filDeMessages(Iterable<Message> messages) {
  final parId = <String, Message>{for (final m in messages) m.id: m};
  final epoque = DateTime.fromMillisecondsSinceEpoch(0);
  return parId.values.toList()..sort((a, b) {
    final dates = (a.dateEnvoi ?? epoque).compareTo(b.dateEnvoi ?? epoque);
    return dates != 0 ? dates : a.id.compareTo(b.id);
  });
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

  /// Le correspondant est connecté (web ou mobile) au moment de la lecture.
  final bool correspondantEnLigne;

  const Conversation({
    required this.id,
    required this.correspondantNom,
    required this.correspondantPrenom,
    required this.messagesNonLus,
    this.correspondantId,
    this.correspondantType,
    this.correspondantPhotoUrl,
    this.dernierMessage,
    this.correspondantEnLigne = false,
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
      dernierMessage: dernier is Map<String, dynamic>
          ? Message.fromJson(dernier)
          : null,
      messagesNonLus: (json['messagesNonLus'] as num?)?.toInt() ?? 0,
      correspondantEnLigne: json['correspondantEnLigne'] == true,
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
