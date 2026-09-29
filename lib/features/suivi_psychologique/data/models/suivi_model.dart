/// Modèle pour une entrée de journal de bord émotionnel
class HumeurEntryModel {
  final String id;
  final DateTime date;
  final int noteHumeur; // 1 (très bas) à 5 (excellent)
  final String emotionDominante;
  final String? noteText;
  final List<String> facteursDeclencheurs;

  const HumeurEntryModel({
    required this.id,
    required this.date,
    required this.noteHumeur,
    required this.emotionDominante,
    this.noteText,
    this.facteursDeclencheurs = const [],
  });

  String get emojiHumeur {
    switch (noteHumeur) {
      case 5:
        return '😄';
      case 4:
        return '🙂';
      case 3:
        return '😐';
      case 2:
        return '😔';
      case 1:
        return '😫';
      default:
        return '🙂';
    }
  }

  factory HumeurEntryModel.fromJson(Map<String, dynamic> json) {
    return HumeurEntryModel(
      id: json['id'] as String? ?? '',
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      noteHumeur: (json['noteHumeur'] as num?)?.toInt() ?? 3,
      emotionDominante: json['emotionDominante'] as String? ?? 'Serein',
      noteText: json['noteText'] as String?,
      facteursDeclencheurs: (json['facteursDeclencheurs'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'noteHumeur': noteHumeur,
      'emotionDominante': emotionDominante,
      if (noteText != null) 'noteText': noteText,
      'facteursDeclencheurs': facteursDeclencheurs,
    };
  }
}
