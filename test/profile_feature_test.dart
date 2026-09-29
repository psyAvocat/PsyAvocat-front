import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:psyavocat_front/features/profile/data/models/profil_model.dart';
import 'package:psyavocat_front/features/profile/data/repositories/profil_repository.dart';
import 'package:psyavocat_front/features/profile/presentation/controllers/profil_controller.dart';
import 'mocks/test_mocks.dart';

void main() {
  group('Profile Feature — Unit & Controller Tests', () {
    test('ProfilModel deserialization and properties format properly', () {
      final json = {
        'id': 'u-123',
        'nom': 'Sow',
        'prenom': 'Fatou',
        'email': 'fatou.sow@psyavocat.com',
        'telephone': '+221 77 999 88 77',
        'ville': 'Dakar',
        'role': 'PATIENT',
        'profileComplet': true,
      };

      final profil = ProfilModel.fromJson(json);

      expect(profil.id, equals('u-123'));
      expect(profil.displayName, equals('Fatou Sow'));
      expect(profil.roleLabel, equals('Patient'));
      expect(profil.profileComplet, isTrue);

      final copy = profil.copyWith(ville: 'Thiès');
      expect(copy.ville, equals('Thiès'));
      expect(copy.prenom, equals('Fatou'));
    });

    test('MockProfilRepository returns default seeded profile', () async {
      final repo = MockProfilRepository();
      final profil = await repo.getCurrentProfile();

      expect(profil, isNotNull);
      expect(profil!.displayName, equals('Amadou Diallo'));
      expect(profil.role, equals('PATIENT'));
    });

    test('ProfilController updates profile fields reactively', () async {
      final mockRepo = MockProfilRepository();
      final container = ProviderContainer(
        overrides: [
          profilRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      // 1. Initial profile
      final initial = await container.read(currentProfilProvider.future);
      expect(initial, isNotNull);

      // 2. Update profile
      final notifier = container.read(currentProfilProvider.notifier);
      final ok = await notifier.updateProfile(
        prenom: 'Ibrahima',
        nom: 'Diallo',
        ville: 'Saint-Louis',
      );

      expect(ok, isTrue);
      final updated = container.read(currentProfilProvider).value;
      expect(updated?.prenom, equals('Ibrahima'));
      expect(updated?.ville, equals('Saint-Louis'));
    });

    test('ProfilController createPatientProfile sets PATIENT role', () async {
      final mockRepo = MockProfilRepository();
      final container = ProviderContainer(
        overrides: [
          profilRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(currentProfilProvider.notifier);
      await notifier.createPatientProfile(
        prenom: 'Mariama',
        nom: 'Ba',
        telephone: '+221 70 111 22 33',
        ville: 'Dakar',
      );

      final profil = container.read(currentProfilProvider).value;
      expect(profil?.displayName, equals('Mariama Ba'));
      expect(profil?.role, equals('PATIENT'));
      expect(profil?.isPatient, isTrue);
    });
  });
}
