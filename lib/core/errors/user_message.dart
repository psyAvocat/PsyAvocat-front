import 'app_exception.dart';
import '../../core/l10n/app_strings.dart';

/// Message affichable à l'utilisateur pour une erreur quelconque.
///
/// Les [AppException] portent déjà un message compréhensible (traduit par
/// l'ErrorInterceptor ou le repository). Les autres erreurs sont techniques :
/// on ne les montre jamais telles quelles.
String userMessageFor(Object error) {
  if (error is AppException) return tr(error.message);
  return tr('Une erreur inattendue est survenue. Veuillez réessayer.');
}
