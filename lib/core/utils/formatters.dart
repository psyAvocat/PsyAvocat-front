import 'package:intl/intl.dart';

/// Utilitaires de formatage (dates, heures, montants).
class Formatters {
  Formatters._();

  /// « 15 octobre 2026 » (« October 15, 2026 » en anglais).
  static String formatLongDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat.yMMMMd().format(date);
  }

  /// « Mar » (jour abrégé ; « Tue » en anglais).
  static String formatJourCourt(DateTime date) => toBeginningOfSentenceCase(
    DateFormat.E().format(date).replaceAll('.', ''),
  );

  /// « mardi 15 octobre 2026 » (« Tuesday, October 15, 2026 » en anglais).
  static String formatJourLong(DateTime date) =>
      DateFormat.yMMMMEEEEd().format(date);

  /// « 09:30 ».
  static String formatHeure(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  /// « 08/10/2026 ».
  static String formatDateCourte(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';

  /// « 08/10/2026 · 09:41 ».
  static String formatDateHeure(DateTime date) =>
      '${formatDateCourte(date)} · ${formatHeure(date)}';

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
