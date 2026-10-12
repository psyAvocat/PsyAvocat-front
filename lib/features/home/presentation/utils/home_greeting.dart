import 'dart:math';
import '../../../../core/l10n/app_strings.dart';

/// Salutation affichée en haut de l'accueil : un titre (selon le moment) et
/// une phrase d'accompagnement.
class HomeGreeting {
  final String titre;
  final String phrase;

  const HomeGreeting(this.titre, this.phrase);
}

/// Moment et tirage figés à l'ouverture de l'application : la salutation ne
/// change pas pendant l'utilisation, mais varie d'une ouverture à l'autre.
final DateTime _ouverture = DateTime.now();
final int _tirage = Random().nextInt(1 << 16);

/// Phrases de l'univers Avocat, tirées au hasard.
const _phrasesAvocat = [
  'Comment pouvons-nous vous aider aujourd’hui ?',
  'Comment allez-vous aujourd’hui ?',
  'Une question de droit ? Nos avocats sont là pour vous.',
  'Avançons ensemble sur vos démarches.',
  'Votre dossier mérite le bon avocat.',
  'Besoin d’un conseil juridique ? Parlons-en.',
];

/// Phrases propres au week-end.
const _phrasesWeekend = [
  'Profitez-en pour faire le point sur vos démarches.',
  'Prenez le temps qu’il vous faut, nous sommes là.',
];

/// Salutation de l'accueil Avocat pour [prenom], au moment de l'ouverture.
HomeGreeting lawyerGreeting(String? prenom) =>
    greetingFor(now: _ouverture, prenom: prenom, tirage: _tirage);

/// Règle de salutation (testable) :
/// - « Bonjour » de 5 h à 17 h 59, « Bonsoir » ensuite ;
/// - vendredi à partir de 14 h et samedi : « Passez un excellent week-end » ;
/// - dimanche : « Bon dimanche » ;
/// - phrase tirée au hasard parmi celles du moment.
HomeGreeting greetingFor({
  required DateTime now,
  required String? prenom,
  required int tirage,
}) {
  final nom = (prenom ?? '').trim();
  String avecNom(String salut) => nom.isEmpty ? tr(salut) : '${tr(salut)} $nom';

  final weekend =
      (now.weekday == DateTime.friday && now.hour >= 14) ||
      now.weekday == DateTime.saturday;
  final dimanche = now.weekday == DateTime.sunday;
  final soir = now.hour >= 18 || now.hour < 5;

  // Une fois sur deux le week-end, la formule de week-end remplace le salut.
  final formuleWeekend = (weekend || dimanche) && tirage.isEven;
  final titre = formuleWeekend
      ? (dimanche
            ? avecNom('Bon dimanche')
            : '${avecNom('Passez un excellent week-end')} !')
      : avecNom(soir ? 'Bonsoir' : 'Bonjour');

  final phrases = formuleWeekend
      ? _phrasesWeekend
      : [..._phrasesAvocat, if (weekend || dimanche) ..._phrasesWeekend];
  return HomeGreeting(titre, tr(phrases[tirage % phrases.length]));
}
