import '../../../../shared/enums/slot_status.dart';

/// Créneau d'un professionnel (GET /api/disponibilites/professionnel/{id}).
class Creneau {
  final String id;
  final DateTime debut;
  final DateTime fin;
  final SlotStatus statut;

  const Creneau({
    required this.id,
    required this.debut,
    required this.fin,
    required this.statut,
  });

  factory Creneau.fromJson(Map<String, dynamic> json) {
    final date = DateTime.parse(json['date'] as String);
    return Creneau(
      id: json['id']?.toString() ?? '',
      debut: _combine(date, json['heureDebut'] as String),
      fin: _combine(date, json['heureFin'] as String),
      statut: SlotStatus.fromApi(json['statut'] as String?),
    );
  }

  /// « 2025-04-15 » + « 09:30:00 » → DateTime local.
  static DateTime _combine(DateTime date, String heure) {
    final parts = heure.split(':');
    return DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(parts[0]),
      parts.length > 1 ? int.parse(parts[1]) : 0,
    );
  }

  DateTime get jour => DateTime(debut.year, debut.month, debut.day);
}
