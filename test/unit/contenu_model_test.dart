import 'package:flutter_test/flutter_test.dart';
import 'package:psyavocat_front/features/contenus/data/models/contenu_model.dart';
import 'package:psyavocat_front/features/notifications/data/models/notification_model.dart';
import 'package:psyavocat_front/core/theme/app_universe.dart';

void main() {
  group('Publication (ContenuModel) Tests', () {
    test('Publication.fromJson maps ARTICLE correctly', () {
      final json = {
        'id': 'art-123',
        'type': 'ARTICLE',
        'titre': 'Guide des procédures prud\'homales',
        'description': 'Un guide complet pour les justiciables',
        'contenu': '<p>Contenu détaillé de l\'article juridique...</p>',
        'imageUrl': 'https://r2.psyavocat.fr/articles/prudhommes.png',
        'auteurNom': 'Dupont',
        'auteurPrenom': 'Jean',
        'specialiteNom': 'Droit du travail',
        'tempsLectureMinutes': 7,
        'datePublication': '2026-10-09T10:00:00Z',
      };

      final publication = Publication.fromJson(json);

      expect(publication.id, equals('art-123'));
      expect(publication.type, equals('ARTICLE'));
      expect(publication.isArticle, isTrue);
      expect(publication.titre, equals('Guide des procédures prud\'homales'));
      expect(
        publication.description,
        equals('Un guide complet pour les justiciables'),
      );
      expect(
        publication.imageUrl,
        equals('https://r2.psyavocat.fr/articles/prudhommes.png'),
      );
      expect(publication.auteurDisplayName, equals('Me Jean Dupont'));
      expect(publication.specialiteNom, equals('Droit du travail'));
      expect(publication.tempsLectureMinutes, equals(7));
    });

    test('Publication.fromJson maps CONSEIL correctly', () {
      final json = {
        'id': 'csl-456',
        'type': 'CONSEIL',
        'titre': 'Gérer le stress avant une audience',
        'description':
            'Conseils pratiques de respiration et de préparation mentale',
        'contenu': '<p>Exercices de cohérence cardiaque...</p>',
        'imageUrl': null,
        'auteurNom': 'Martin',
        'auteurPrenom': 'Claire',
        'specialiteNom': 'Gestion du stress',
        'tempsLectureMinutes': 4,
        'datePublication': '2026-10-08T15:30:00Z',
      };

      final publication = Publication.fromJson(json);

      expect(publication.id, equals('csl-456'));
      expect(publication.type, equals('CONSEIL'));
      expect(publication.isArticle, isFalse);
      expect(publication.titre, equals('Gérer le stress avant une audience'));
      expect(publication.imageUrl, isNull);
      expect(publication.auteurDisplayName, equals('Dr Claire Martin'));
      expect(publication.tempsLectureMinutes, equals(4));
    });
  });

  group('NotificationItem Tests', () {
    test('maps AVOCAT notification and universe', () {
      final json = {
        'id': 'notif-1',
        'type': 'NOUVEAU_RENDEZ_VOUS',
        'titre': 'Nouveau rendez-vous',
        'contenu': 'Votre consultation juridique est confirmée.',
        'dateEnvoi': '2026-10-09T09:00:00Z',
        'lu': false,
        'univers': 'AVOCAT',
        'ressourceType': 'RENDEZ_VOUS',
        'ressourceId': 'rdv-789',
      };

      final notif = NotificationItem.fromJson(json);

      expect(notif.id, equals('notif-1'));
      expect(notif.type, equals('NOUVEAU_RENDEZ_VOUS'));
      expect(notif.titre, equals('Nouveau rendez-vous'));
      expect(
        notif.contenu,
        equals('Votre consultation juridique est confirmée.'),
      );
      expect(notif.lu, isFalse);
      expect(notif.isRead, isFalse);
      expect(notif.universe, equals(AppUniverse.lawyer));
      expect(notif.ressourceType, equals('RENDEZ_VOUS'));
      expect(notif.ressourceId, equals('rdv-789'));
    });

    test('maps PSYCHOLOGUE notification and universe', () {
      final json = {
        'id': 'notif-2',
        'type': 'NOUVEAU_CONSEIL',
        'titre': 'Nouveau conseil disponible',
        'contenu':
            'Un nouveau conseil en gestion du stress vient d\'être publié.',
        'dateEnvoi': '2026-10-09T08:00:00Z',
        'lu': true,
        'univers': 'PSYCHOLOGUE',
        'ressourceType': 'CONSEIL',
        'ressourceId': 'csl-456',
      };

      final notif = NotificationItem.fromJson(json);

      expect(notif.universe, equals(AppUniverse.psychologist));
      expect(notif.lu, isTrue);
      expect(notif.isRead, isTrue);
    });
  });
}
