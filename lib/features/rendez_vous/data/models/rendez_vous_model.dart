class RendezVousItem {
  final String id;
  final String day;
  final String month;
  final String year;
  final String time;
  final String proId;
  final String proName;
  final String proRole;
  final String specialty;
  final String mode;
  final String status; // 'Confirmé', 'En attente', 'Passé', 'Annulé'
  final int montantTotal;
  final int montantAcompte;
  final String? motif;

  const RendezVousItem({
    required this.id,
    required this.day,
    required this.month,
    required this.year,
    required this.time,
    required this.proId,
    required this.proName,
    required this.proRole,
    required this.specialty,
    required this.mode,
    required this.status,
    required this.montantTotal,
    required this.montantAcompte,
    this.motif,
  });

  String get formattedMontantTotal {
    final s = montantTotal.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(s[i]);
    }
    return '${buffer.toString()} FCFA';
  }

  String get formattedAcompte {
    final s = montantAcompte.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(s[i]);
    }
    return '${buffer.toString()} FCFA';
  }
}
