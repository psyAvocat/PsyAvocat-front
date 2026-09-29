/// Modèle représentant une transaction / paiement dans PsyAvocat
class PaiementModel {
  final String id;
  final String reference;
  final String description;
  final int montant;
  final String moyenPaiement; // WAVE | ORANGE_MONEY | CARTE_BANCAIRE | ESPECES
  final String statut; // PAYE | EN_ATTENTE | ECHOUE
  final DateTime date;
  final String proName;
  final String proRole;

  const PaiementModel({
    required this.id,
    required this.reference,
    required this.description,
    required this.montant,
    required this.moyenPaiement,
    required this.statut,
    required this.date,
    required this.proName,
    required this.proRole,
  });

  String get formattedMontant {
    final s = montant.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(s[i]);
    }
    return '${buffer.toString()} FCFA';
  }

  factory PaiementModel.fromJson(Map<String, dynamic> json) {
    return PaiementModel(
      id: json['id'] as String? ?? '',
      reference: json['reference'] as String? ?? '',
      description: json['description'] as String? ?? '',
      montant: (json['montant'] as num?)?.toInt() ?? 0,
      moyenPaiement: json['moyenPaiement'] as String? ?? 'WAVE',
      statut: json['statut'] as String? ?? 'PAYE',
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      proName: json['proName'] as String? ?? '',
      proRole: json['proRole'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reference': reference,
      'description': description,
      'montant': montant,
      'moyenPaiement': moyenPaiement,
      'statut': statut,
      'date': date.toIso8601String(),
      'proName': proName,
      'proRole': proRole,
    };
  }
}
