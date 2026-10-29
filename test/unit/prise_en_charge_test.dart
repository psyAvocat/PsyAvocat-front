import 'package:flutter_test/flutter_test.dart';
import 'package:psyavocat_front/core/navigation/deep_link.dart';
import 'package:psyavocat_front/core/router/app_routes.dart';
import 'package:psyavocat_front/features/notifications/data/models/notification_model.dart';
import 'package:psyavocat_front/features/rendez_vous/data/models/rendez_vous_model.dart';

/// Dossier accepté par un avocat : liens vers l'écran de prise en charge et
/// rendez-vous rattaché au dossier.
void main() {
  group('Liens des notifications de dossier', () {
    NotificationItem notification(String type) => NotificationItem.fromJson({
      'id': 'n1',
      'type': type,
      'titre': 'Dossier',
      'contenu': '…',
      'lu': false,
      'ressourceType': 'DOSSIER',
      'ressourceId': 'd1',
    });

    test('« Dossier accepté » ouvre la prise en charge du dossier', () {
      expect(
        notification('DOSSIER_ACCEPTE').targetRoute,
        AppRoutes.dossierPriseEnCharge('d1'),
      );
      expect(
        AppRoutes.dossierPriseEnCharge('d1'),
        '/dossiers/d1/prise-en-charge',
      );
    });

    test('les autres notifications de dossier ouvrent le dossier', () {
      expect(
        notification('DOSSIER_REFUSE').targetRoute,
        AppRoutes.dossier('d1'),
      );
    });

    test('notification push : même destination selon le type', () {
      final accepte = DeepLinkTarget.fromData({
        'type': 'DOSSIER_ACCEPTE',
        'univers': 'AVOCAT',
        'ressourceType': 'DOSSIER',
        'ressourceId': 'd1',
      });
      final refuse = DeepLinkTarget.fromData({
        'type': 'DOSSIER_REFUSE',
        'univers': 'AVOCAT',
        'ressourceType': 'DOSSIER',
        'ressourceId': 'd1',
      });
      expect(accepte.location, AppRoutes.dossierPriseEnCharge('d1'));
      expect(refuse.location, AppRoutes.dossier('d1'));
    });
  });

  test('un rendez-vous avocat porte le dossier concerné', () {
    final rdv = RendezVous.fromJson({
      'id': 'r1',
      'dateHeure': '2026-11-02T10:00:00',
      'statut': 'CONFIRME',
      'professionnelId': 'a1',
      'professionnelNom': 'Diallo',
      'professionnelPrenom': 'Awa',
      'typeProfessionnel': 'AVOCAT',
      'soumissionId': 's1',
      'dossierId': 'd1',
      'dossierTitre': 'Litige bail',
    });
    expect(rdv.dossierId, 'd1');
    expect(rdv.dossierTitre, 'Litige bail');
    expect(rdv.soumissionId, 's1');
  });
}
