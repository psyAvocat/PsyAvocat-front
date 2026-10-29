import 'package:flutter_test/flutter_test.dart';
import 'package:psyavocat_front/core/router/app_routes.dart';
import 'package:psyavocat_front/core/utils/visio.dart';
import 'package:psyavocat_front/features/notifications/data/models/notification_model.dart';

void main() {
  test(
    'lien d’entrée dans la salle : français, entrée directe, nom du participant',
    () {
      expect(
        lienPourRejoindre(
          'https://visio.test/PsyAvocat-abc',
          nom: 'Awa Traoré',
        ),
        'https://visio.test/PsyAvocat-abc#config.prejoinPageEnabled=false'
        '&config.defaultLanguage=%22fr%22'
        '&userInfo.displayName=%22Awa%20Traor%C3%A9%22',
      );
    },
  );

  test('seules les salles PsyAvocat sont présentées comme une visio', () {
    expect(estSalleVisio('https://visio.test/PsyAvocat-abc'), isTrue);
    expect(estSalleVisio('https://www.service-public.fr/droits'), isFalse);
  });

  test('rappel de visio : lien de la salle et ouverture du rendez-vous', () {
    final rappel = NotificationItem.fromJson({
      'id': 'n1',
      'type': 'RAPPEL_VISIO',
      'titre': 'Visioconférence dans 12 min',
      'contenu': 'Votre visioconférence avec Dr Marc Dupont commence à 10h30.',
      'lu': false,
      'ressourceType': 'RENDEZ_VOUS',
      'ressourceId': 'rdv-1',
      'lienVisio': 'https://visio.test/PsyAvocat-abc',
    });

    expect(rappel.lienVisio, 'https://visio.test/PsyAvocat-abc');
    expect(rappel.targetRoute, AppRoutes.rendezVousDetail('rdv-1'));
  });
}
