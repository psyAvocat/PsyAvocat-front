import 'package:flutter_test/flutter_test.dart';
import 'package:psyavocat_front/features/rendez_vous/data/models/rendez_vous_model.dart';
import 'package:psyavocat_front/shared/enums/appointment_status.dart';
import 'package:psyavocat_front/core/theme/app_universe.dart';

void main() {
  group('RendezVous Model Tests', () {
    test('parses Lawyer appointment with CONFIRME status', () {
      final json = {
        'id': 'rdv-101',
        'dateHeure': '2026-10-15T14:30:00Z',
        'dateFin': '2026-10-15T15:15:00Z',
        'dureeMinutes': 45,
        'statut': 'CONFIRME',
        'mode': 'VISIO',
        'lienVisio': 'https://meet.psyavocat.fr/rdv-101',
        'motif': 'Consultation droit des contrats',
        'montantTotal': 120.0,
        'devise': 'EUR',
        'professionnelId': 'pro-1',
        'professionnelNom': 'Durand',
        'professionnelPrenom': 'Alice',
        'typeProfessionnel': 'AVOCAT',
        'professionnelSpecialite': 'Droit des affaires',
      };

      final rdv = RendezVous.fromJson(json);

      expect(rdv.id, equals('rdv-101'));
      expect(rdv.statut, equals(AppointmentStatus.confirme));
      expect(rdv.universe, equals(AppUniverse.lawyer));
      expect(rdv.professionnelDisplayName, equals('Me Alice Durand'));
      expect(rdv.mode, equals('VISIO'));
      expect(rdv.lienVisio, equals('https://meet.psyavocat.fr/rdv-101'));
      expect(rdv.montantTotal, equals(120.0));
      expect(rdv.dureeMinutes, equals(45));

      final nowBefore = DateTime.parse('2026-10-15T10:00:00Z');
      expect(rdv.phaseAt(nowBefore), equals(AppointmentPhase.aVenir));
      expect(rdv.canBeChangedAt(nowBefore), isTrue);

      final nowAfter = DateTime.parse('2026-10-15T16:00:00Z');
      expect(rdv.phaseAt(nowAfter), equals(AppointmentPhase.passe));
      expect(rdv.canBeChangedAt(nowAfter), isFalse);
    });

    test('parses Psychologist appointment with EN_ATTENTE status', () {
      final json = {
        'id': 'rdv-202',
        'dateHeure': '2026-10-16T10:00:00Z',
        'dureeMinutes': 50,
        'statut': 'EN_ATTENTE',
        'mode': 'CABINET',
        'adresseCabinet': '12 rue de la Paix, 75002 Paris',
        'motif': 'Premier entretien de soutien',
        'professionnelId': 'pro-2',
        'professionnelNom': 'Moreau',
        'professionnelPrenom': 'Marc',
        'typeProfessionnel': 'PSYCHOLOGUE',
      };

      final rdv = RendezVous.fromJson(json);

      expect(rdv.id, equals('rdv-202'));
      expect(rdv.statut, equals(AppointmentStatus.enAttente));
      expect(rdv.universe, equals(AppUniverse.psychologist));
      expect(rdv.professionnelDisplayName, equals('Dr Marc Moreau'));
      expect(rdv.mode, equals('CABINET'));
      expect(rdv.adresseCabinet, equals('12 rue de la Paix, 75002 Paris'));
      expect(rdv.fin, equals(DateTime.parse('2026-10-16T10:50:00Z')));
    });
    test('réponse réelle de GET /api/rendez-vous (psychologue, heure locale)', () {
      // Copie d'une réponse du backend après une réservation depuis l'application.
      final json = {
        'id': '944b99d8-9133-4af3-b812-7e1feb934eba',
        'dateHeure': '2026-10-14T09:00:00',
        'statut': 'CONFIRME',
        'mode': 'VISIO',
        'patientId': 'client-1',
        'patientNom': 'Traoré',
        'patientPrenom': 'Awa',
        'professionnelId': 'psy-1',
        'professionnelNom': 'Visuel',
        'professionnelPrenom': 'Camille',
        'typeProfessionnel': 'PSYCHOLOGUE',
        'montantTotal': 15000.0,
        'montantAcompte': 3000.0,
        'statutPaiement': 'PAYE',
        'dateFin': '2026-10-14T09:50:00',
        'dureeMinutes': 50,
        'motif': 'Premier échange',
        'devise': 'XOF',
        'disponibiliteId': 'dispo-1',
        'professionnelPhotoUrl': 'https://exemple/photo.jpg',
        'professionnelSpecialite': 'Thérapie cognitive',
      };

      final rdv = RendezVous.fromJson(json);

      expect(rdv.universe, AppUniverse.psychologist);
      expect(rdv.statut, AppointmentStatus.confirme);
      expect(rdv.dateHeure, DateTime(2026, 10, 14, 9));
      expect(rdv.professionnelPhotoUrl, 'https://exemple/photo.jpg');
      expect(rdv.phaseAt(DateTime(2026, 10, 13, 18)), AppointmentPhase.aVenir);
    });
  });
}
