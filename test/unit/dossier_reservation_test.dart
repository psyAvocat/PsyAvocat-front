import 'package:flutter_test/flutter_test.dart';
import 'package:psyavocat_front/features/dossiers/data/models/dossier_model.dart';
import 'package:psyavocat_front/features/dossiers/data/repositories/dossier_repository.dart';
import 'package:psyavocat_front/features/professionnels/data/models/creneau.dart';
import 'package:psyavocat_front/features/professionnels/data/models/professionnel_detail.dart';
import 'package:psyavocat_front/features/professionnels/data/models/professionnel_summary.dart';
import 'package:psyavocat_front/features/rendez_vous/data/models/reservation_contexte.dart';
import 'package:psyavocat_front/shared/enums/slot_status.dart';

void main() {
  group('DossierModel (contrat DossierResponseDTO)', () {
    final json = {
      'id': 'd1',
      'titre': 'Litige bail',
      'description': 'Contestation',
      'dateOuverture': '2026-10-01',
      'statut': 'PRIS_EN_CHARGE',
      'specialiteNom': 'Droit immobilier',
      'piecesJointes': [
        {'id': 'pj1', 'nom': 'bail.pdf', 'url': 'https://r2.example/presigned'},
      ],
      'soumissions': [
        {
          'id': 's1',
          'avocatId': 'a1',
          'avocatNom': 'Diallo',
          'avocatPrenom': 'Awa',
          'statut': 'ACCEPTEE',
          'tarifPropose': 250000,
        },
        {
          'id': 's2',
          'avocatId': 'a2',
          'avocatNom': 'Traoré',
          'avocatPrenom': 'Ali',
          'statut': 'CADUQUE',
        },
      ],
    };

    test(
      'lit les champs réels du backend (dateOuverture, tarifPropose, pièces)',
      () {
        final d = DossierModel.fromJson(json);
        expect(d.dateOuverture, DateTime(2026, 10, 1));
        expect(d.domaineNom, 'Droit immobilier');
        expect(d.piecesJointes.single.nom, 'bail.pdf');
        expect(d.soumissions.first.tarifPropose, 250000);
        expect(d.estPrisEnCharge, isTrue);
      },
    );

    test('la soumission retenue est celle acceptée, jamais une caduque', () {
      final d = DossierModel.fromJson(json);
      expect(d.soumissionRetenue?.avocatId, 'a1');
    });
  });

  group('Réservation et acompte simulé', () {
    final pro = ProfessionnelDetail(
      summary: const ProfessionnelSummary(
        id: 'p1',
        fullName: 'Awa Diallo',
        type: 'PSYCHOLOGUE',
      ),
    );
    final creneau = Creneau(
      id: 'c1',
      debut: DateTime(2026, 10, 20, 9),
      fin: DateTime(2026, 10, 20, 10),
      statut: SlotStatus.libre,
    );

    test('psychologue : montant = tarif publié, acompte 20 %', () {
      const tarif = Tarif(
        id: 't1',
        titre: 'Séance',
        montant: 25000,
        devise: 'XOF',
      );
      final recap = ReservationRecap(
        contexte: const ReservationContexte.psychologue(
          professionnelId: 'p1',
          tarif: tarif,
        ),
        professionnel: pro,
        creneau: creneau,
        mode: 'VISIO',
      );
      expect(recap.montantTotal, 25000);
      expect(recap.acompteEstime, 5000);
      expect(recap.contexte.viaDossier, isFalse);
    });

    test('avocat : montant = honoraires acceptés du dossier', () {
      final recap = ReservationRecap(
        contexte: const ReservationContexte.avocat(
          professionnelId: 'a1',
          soumissionId: 's1',
          dossierTitre: 'Litige bail',
          montantDossier: 250000,
        ),
        professionnel: pro,
        creneau: creneau,
        mode: 'CABINET',
      );
      expect(recap.montantTotal, 250000);
      expect(recap.acompteEstime, 50000);
      expect(recap.contexte.viaDossier, isTrue);
    });
  });

  test('type MIME déclaré pour les pièces jointes', () {
    expect(typeMimeDe('contrat.PDF'), 'application/pdf');
    expect(typeMimeDe('photo.jpeg'), 'image/jpeg');
    expect(
      typeMimeDe('lettre.docx'),
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    );
  });
}
