import 'package:intl/intl.dart';

/// Utilitaires de formatage de dates et de montants.
class Formatters {
  Formatters._();

  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
  static final DateFormat _timeFormat = DateFormat('HH:mm');

  static String formatDate(DateTime? date) {
    if (date == null) return '-';
    return _dateFormat.format(date);
  }

  static String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '-';
    return _dateTimeFormat.format(dateTime);
  }

  static String formatTime(DateTime? time) {
    if (time == null) return '-';
    return _timeFormat.format(time);
  }

  static String formatCurrency(num? amount, [String currency = '€']) {
    if (amount == null) return '-';
    final numberFormat = NumberFormat.currency(
      symbol: currency,
      decimalDigits: 2,
      locale: 'fr_FR',
    );
    return numberFormat.format(amount);
  }
}
