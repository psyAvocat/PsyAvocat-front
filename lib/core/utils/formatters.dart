/// Utilitaires de formatage (dates, heures, montants).
class Formatters {
  Formatters._();

  static const List<String> _moisFr = [
    'janvier',
    'février',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'août',
    'septembre',
    'octobre',
    'novembre',
    'décembre',
  ];

  /// « 15 octobre 2026 » (sans dépendre des données de locale d'intl).
  static String formatLongDate(DateTime? date) {
    if (date == null) return '-';
    return '${date.day} ${_moisFr[date.month - 1]} ${date.year}';
  }

  static const List<String> _joursCourts = [
    'Lun',
    'Mar',
    'Mer',
    'Jeu',
    'Ven',
    'Sam',
    'Dim',
  ];

  static const List<String> _jours = [
    'lundi',
    'mardi',
    'mercredi',
    'jeudi',
    'vendredi',
    'samedi',
    'dimanche',
  ];

  /// « Mar » (jour abrégé).
  static String formatJourCourt(DateTime date) => _joursCourts[date.weekday - 1];

  /// « mardi 15 octobre 2026 ».
  static String formatJourLong(DateTime date) =>
      '${_jours[date.weekday - 1]} ${formatLongDate(date)}';

  /// « 09:30 ».
  static String formatHeure(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  /// « 150 000 FCFA » (montants en francs CFA, sans décimales).
  static String formatFcfa(num montant) {
    final s = montant.round().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(s[i]);
    }
    return '${buffer.toString()} FCFA';
  }
}
