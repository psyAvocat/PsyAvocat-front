import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'en_strings.dart';

/// Langues de l'interface.
const supportedAppLocales = [Locale('fr', 'FR'), Locale('en')];

String _langue = 'fr';

/// Langue courante (`fr` ou `en`).
String get appLanguage => _langue;

/// Change la langue des textes, des dates (`DateFormat`) et des nombres.
/// Appelé par les réglages ; l'interface est ensuite reconstruite.
void setAppLanguage(String code) {
  _langue = code == 'en' ? 'en' : 'fr';
  Intl.defaultLocale = _langue == 'en' ? 'en' : 'fr_FR';
}

/// Texte de l'interface dans la langue courante.
///
/// La clé est le texte français (langue de référence) : sans traduction
/// anglaise connue, le texte français s'affiche. Les valeurs variables
/// s'écrivent `{nom}` dans le texte et sont passées dans [args] :
/// `tr('Écrire à {nom}', {'nom': pro.displayName})`.
String tr(String fr, [Map<String, Object?> args = const {}]) {
  var texte = _langue == 'en' ? (enStrings[fr] ?? fr) : fr;
  args.forEach((cle, valeur) => texte = texte.replaceAll('{$cle}', '$valeur'));
  return texte;
}

/// Reconstruit tout l'arbre de widgets sous [context] : après un changement
/// de langue, même les widgets constants relisent leurs textes.
void rebuildAllChildren(BuildContext context) {
  void reconstruire(Element element) {
    element.markNeedsBuild();
    element.visitChildren(reconstruire);
  }

  (context as Element).visitChildren(reconstruire);
}
