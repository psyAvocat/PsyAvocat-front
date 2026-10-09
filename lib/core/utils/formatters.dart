/// Utilitaires de formatage de dates.
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
}
