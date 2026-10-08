import 'package:psyavocat_front/features/notifications/data/models/notification_model.dart';
import 'package:psyavocat_front/features/notifications/data/repositories/notifications_repository.dart';
import 'package:psyavocat_front/features/professionnels/data/models/professional_detail_model.dart';
import 'package:psyavocat_front/features/professionnels/data/models/professionnel_summary.dart';
import 'package:psyavocat_front/features/professionnels/data/repositories/professionnels_repository.dart';
import 'package:psyavocat_front/features/profile/data/models/profil_model.dart';
import 'package:psyavocat_front/features/profile/data/repositories/profil_repository.dart';
import 'package:psyavocat_front/features/rendez_vous/data/models/rendez_vous_model.dart';
import 'package:psyavocat_front/features/rendez_vous/data/repositories/rendez_vous_repository.dart';

/// Mock pour les tests unitaires de ProfessionnelsRepository avec fixtures de test
class MockProfessionnelsRepository implements ProfessionnelsRepository {
  final List<ProfessionalDetail> mockPros;

  MockProfessionnelsRepository([List<ProfessionalDetail>? pros])
      : mockPros = pros ?? _defaultMockPros;

  static final List<ProfessionalDetail> _defaultMockPros = [
    const ProfessionalDetail(
      id: 'avocat-sangare',
      nom: 'Maître Sangaré',
      titre: 'Avocat au barreau',
      specialitePrincipale: 'Droit des affaires',
      specialites: ['Droit des affaires', 'Droit du travail'],
      ville: 'Bamako',
      adresse: 'Hamdallaye ACI 2000',
      distance: 'Bamako • 1,2 km',
      imagePath: 'assets/images/onboarding_lawyer.png',
      note: 4.9,
      nombreAvis: 138,
      biographie: 'Avocat au barreau spécialisé en conseil juridique et contentieux.',
      tarifs: [
        ProfessionalTarif(
          titre: 'Consultation initiale',
          montantFcfa: 200000,
          description: 'Cadrage de dossier',
        ),
        ProfessionalTarif(
          titre: 'Suivi contentieux',
          montantFcfa: 50000,
          description: 'Assistance complète',
        ),
      ],
      langues: ['Français', 'Bambara'],
      enLigne: true,
      isAvocat: true,
      disponibilites: [
        DisponibiliteJour(
          date: '2025-05-15',
          labelJour: 'Jeu',
          labelNumero: '15',
          labelMois: 'Mai',
          creneaux: ['10:00', '14:00'],
        ),
      ],
    ),
    const ProfessionalDetail(
      id: 'avocat-dubois',
      nom: 'Maître Claire Dubois',
      titre: 'Avocate au barreau',
      specialitePrincipale: 'Droit de la famille',
      specialites: ['Droit de la famille'],
      ville: 'Paris',
      adresse: '8e arrondissement',
      distance: 'Paris • 3 km',
      imagePath: 'assets/images/onboarding_lawyer.png',
      note: 4.8,
      nombreAvis: 32,
      biographie: 'Spécialiste des questions familiales et patrimoniales.',
      tarifs: [
        ProfessionalTarif(
          titre: 'Consultation familiale',
          montantFcfa: 30000,
          description: 'Entretien approfondi',
        ),
      ],
      langues: ['Français'],
      enLigne: true,
      isAvocat: true,
      disponibilites: [],
    ),
    const ProfessionalDetail(
      id: 'psy-lambert',
      nom: 'Dr. Marc Lambert',
      titre: 'Psychologue clinicien',
      specialitePrincipale: 'Thérapie comportementale',
      specialites: ['Thérapie comportementale'],
      ville: 'Dakar',
      adresse: 'Fann Résidence',
      distance: 'Dakar • 2 km',
      imagePath: 'assets/images/onboarding_psy.png',
      note: 4.9,
      nombreAvis: 29,
      biographie: 'Thérapeute spécialisé en anxiété et stress.',
      tarifs: [
        ProfessionalTarif(
          titre: 'Séance de thérapie',
          montantFcfa: 35000,
          description: 'Séance 50 min',
        ),
      ],
      langues: ['Français'],
      enLigne: true,
      isAvocat: false,
      disponibilites: [],
    ),
  ];

  @override
  Future<List<ProfessionnelSummary>> searchProfessionnels({String? type}) async {
    return mockPros
        .where((p) => type == null || (type == 'AVOCAT') == p.isAvocat)
        .map(
          (p) => ProfessionnelSummary(
            id: p.id,
            fullName: p.nom,
            ville: p.ville,
            specialites: p.specialites,
            noteMoyenne: p.note,
            nombreAvis: p.nombreAvis,
          ),
        )
        .toList();
  }

  @override
  Future<ProfessionalDetail?> getProfessionnelById(String id) async {
    try {
      return mockPros.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}

/// Mock pour les tests unitaires de ProfilRepository
class MockProfilRepository implements ProfilRepository {
  ProfilModel? _current = const ProfilModel(
    id: 'user-mock-1',
    nom: 'Diallo',
    prenom: 'Amadou',
    email: 'amadou.diallo@psyavocat.com',
    telephone: '+221 77 123 45 67',
    ville: 'Dakar',
    role: 'PATIENT',
    profileComplet: true,
  );

  @override
  Future<ProfilModel?> getCurrentProfile() async => _current;

  @override
  Future<ProfilModel> updateProfile({
    String? nom,
    String? prenom,
    String? telephone,
    String? ville,
  }) async {
    _current = (_current ?? const ProfilModel(id: 'test', nom: '', prenom: '', email: '', role: 'PATIENT'))
        .copyWith(nom: nom, prenom: prenom, telephone: telephone, ville: ville);
    return _current!;
  }

  @override
  Future<ProfilModel> createPatientProfile({
    required String nom,
    required String prenom,
    String? telephone,
    String? ville,
  }) async {
    _current = ProfilModel(
      id: 'patient-mock',
      nom: nom,
      prenom: prenom,
      email: 'patient@psyavocat.com',
      telephone: telephone,
      ville: ville,
      role: 'PATIENT',
      profileComplet: true,
    );
    return _current!;
  }

  @override
  Future<ProfilModel> createJusticiableProfile({
    required String nom,
    required String prenom,
    String? telephone,
    String? ville,
  }) async {
    _current = ProfilModel(
      id: 'justiciable-mock',
      nom: nom,
      prenom: prenom,
      email: 'justiciable@psyavocat.com',
      telephone: telephone,
      ville: ville,
      role: 'JUSTICIABLE',
      profileComplet: true,
    );
    return _current!;
  }
}

/// Mock pour les tests unitaires de NotificationsRepository
class MockNotificationsRepository implements NotificationsRepository {
  final List<NotificationModel> _notifications;

  MockNotificationsRepository([List<NotificationModel>? notifs])
      : _notifications = notifs ?? [
          NotificationModel(
            id: 'mock-notif-1',
            titre: 'Rappel de consultation',
            message: 'Votre consultation est prévue demain.',
            date: DateTime.now().subtract(const Duration(hours: 1)),
            type: 'RDV',
            isRead: false,
            targetRoute: '/rendez-vous',
          ),
          NotificationModel(
            id: 'mock-notif-2',
            titre: 'Nouveau message',
            message: 'Vous avez reçu une réponse.',
            date: DateTime.now().subtract(const Duration(hours: 3)),
            type: 'MESSAGE',
            isRead: true,
            targetRoute: '/messagerie',
          ),
        ];

  @override
  Future<List<NotificationModel>> getNotifications() async => List.unmodifiable(_notifications);

  @override
  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
    }
  }

  @override
  Future<void> markAllAsRead() async {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
  }

  @override
  Future<void> deleteNotification(String id) async {
    _notifications.removeWhere((n) => n.id == id);
  }
}

/// Mock pour les tests unitaires de RendezVousRepository
class MockRendezVousRepository implements RendezVousRepository {
  final List<RendezVousItem> _items = [
    const RendezVousItem(
      id: 'mock-rdv-1',
      day: '18',
      month: 'Avr.',
      year: '2025',
      time: '14:00 - 15:00',
      proId: 'avocat-sangare',
      proName: 'Maître Sangaré',
      proRole: 'Avocat',
      specialty: 'Droit du travail',
      mode: 'En ligne (visioconférence)',
      status: 'Confirmé',
      montantTotal: 50000,
      montantAcompte: 10000,
      motif: 'Consultation initiale',
    ),
  ];

  @override
  Future<List<RendezVousItem>> getMyRendezVous() async => List.unmodifiable(_items);

  @override
  Future<RendezVousItem> createRendezVousDirect({
    required String proId,
    required bool isAvocat,
    required String disponibiliteId,
    required String mode,
    required double montantTotal,
    String? motif,
  }) async {
    final newItem = RendezVousItem(
      id: 'mock-rdv-${DateTime.now().millisecondsSinceEpoch}',
      day: '20',
      month: 'Avr.',
      year: '2025',
      time: '10:00 - 11:00',
      proId: proId,
      proName: 'Professionnel Test',
      proRole: isAvocat ? 'Avocat' : 'Psychologue',
      specialty: 'Général',
      mode: mode,
      status: 'Confirmé',
      montantTotal: montantTotal.toInt(),
      montantAcompte: (montantTotal * 0.20).round(),
      motif: motif,
    );
    _items.add(newItem);
    return newItem;
  }

  @override
  Future<void> annulerRendezVous(String id) async {
    final index = _items.indexWhere((r) => r.id == id);
    if (index != -1) {
      final r = _items[index];
      _items[index] = RendezVousItem(
        id: r.id,
        day: r.day,
        month: r.month,
        year: r.year,
        time: r.time,
        proId: r.proId,
        proName: r.proName,
        proRole: r.proRole,
        specialty: r.specialty,
        mode: r.mode,
        status: 'Annulé',
        montantTotal: r.montantTotal,
        montantAcompte: r.montantAcompte,
        motif: r.motif,
      );
    }
  }
}
