import 'package:flutter_test/flutter_test.dart';
import 'package:psyavocat_front/core/config/app_config.dart';
import 'package:psyavocat_front/core/services/firebase_auth_service.dart';
import 'package:psyavocat_front/firebase_options.dart';
import 'package:psyavocat_front/shared/enums/user_role.dart';

void main() {
  group('Firebase Auth & Messaging Service Configuration Tests', () {
    test('AppConfig constants are valid for Firebase integration', () {
      expect(AppConfig.appName, equals('PsyAvocat'));
      expect(AppConfig.apiBaseUrl, isNotEmpty);
      expect(AppConfig.fcmWebVapidKey, isA<String>());
    });

    test('UserRole enum parses correctly', () {
      expect(UserRole.fromCode('AVOCAT'), equals(UserRole.avocat));
      expect(UserRole.fromCode('PSYCHOLOGUE'), equals(UserRole.psychologue));
      expect(UserRole.fromCode('PATIENT'), equals(UserRole.patient));
    });

    test('DefaultFirebaseOptions contains valid psyavocat project configs', () {
      expect(DefaultFirebaseOptions.android.projectId, equals('psyavocat'));
      expect(DefaultFirebaseOptions.android.appId,
          equals('1:434795703982:android:bed067525aeed62625073f'));

      expect(DefaultFirebaseOptions.ios.projectId, equals('psyavocat'));
      expect(DefaultFirebaseOptions.ios.appId,
          equals('1:434795703982:ios:aee60f4d5b8f06b525073f'));
      expect(DefaultFirebaseOptions.ios.iosBundleId,
          equals('com.example.psyavocatFront'));

      expect(DefaultFirebaseOptions.web.projectId, equals('psyavocat'));
      expect(DefaultFirebaseOptions.web.appId,
          equals('1:434795703982:web:831984cce60ce32b25073f'));
      expect(DefaultFirebaseOptions.web.authDomain,
          equals('psyavocat.firebaseapp.com'));
    });

    test('FirebaseAuthService maps technical Firebase errors to friendly messages', () {
      expect(
        FirebaseAuthService.mapFirebaseError('user-not-found'),
        contains('Aucun utilisateur'),
      );
      expect(
        FirebaseAuthService.mapFirebaseError('wrong-password'),
        contains('Identifiants incorrects'),
      );
      expect(
        FirebaseAuthService.mapFirebaseError('invalid-credential'),
        contains('Identifiants incorrects'),
      );
      expect(
        FirebaseAuthService.mapFirebaseError('email-already-in-use'),
        contains('déjà associée'),
      );
      expect(
        FirebaseAuthService.mapFirebaseError('weak-password'),
        contains('faible'),
      );
      expect(
        FirebaseAuthService.mapFirebaseError('user-disabled'),
        contains('désactivé'),
      );
      expect(
        FirebaseAuthService.mapFirebaseError('operation-not-allowed'),
        contains('n\'est pas activée'),
      );
      expect(
        FirebaseAuthService.mapFirebaseError('too-many-requests'),
        contains('Trop de tentatives'),
      );
      expect(
        FirebaseAuthService.mapFirebaseError('network-request-failed'),
        contains('réseau'),
      );
      expect(
        FirebaseAuthService.mapFirebaseError('unknown-code', 'Erreur personnalisée'),
        equals('Erreur personnalisée'),
      );
    });
  });
}
