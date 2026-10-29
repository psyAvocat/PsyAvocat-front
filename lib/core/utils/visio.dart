import 'dart:convert';

import 'package:url_launcher/url_launcher.dart';

/// Visioconférences des rendez-vous : chaque rendez-vous en visio a sa salle
/// (lien Jitsi généré par le serveur, remis au client et au professionnel).

/// Lien d'une salle de visio PsyAvocat (et non d'un site quelconque).
bool estSalleVisio(String url) => url.contains('/PsyAvocat-');

/// Lien d'entrée dans la salle : interface en français, entrée directe (sans
/// page d'attente) et nom du participant déjà renseigné.
String lienPourRejoindre(String lien, {String? nom}) {
  String json(String valeur) => Uri.encodeComponent(jsonEncode(valeur));
  final options = [
    'config.prejoinPageEnabled=false',
    'config.defaultLanguage=${json('fr')}',
    if (nom != null && nom.trim().isNotEmpty)
      'userInfo.displayName=${json(nom.trim())}',
  ];
  return '$lien${lien.contains('#') ? '&' : '#'}${options.join('&')}';
}

/// Ouvre la salle (application Jitsi si elle est installée, sinon le
/// navigateur). Renvoie `false` si aucun des deux n'a pu l'ouvrir.
Future<bool> rejoindreVisio(String lien, {String? nom}) async {
  final uri = Uri.tryParse(lienPourRejoindre(lien.trim(), nom: nom));
  if (uri == null) return false;
  if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return true;
  return launchUrl(uri, mode: LaunchMode.platformDefault);
}
