import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psyavocat_front/core/push/device_repository.dart';
import 'package:psyavocat_front/core/push/notifications_systeme.dart';
import 'package:psyavocat_front/core/push/push_service.dart';
import 'package:psyavocat_front/core/services/app_preferences_service.dart';
import 'package:psyavocat_front/core/services/firebase_messaging_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MessagingFake implements FirebaseMessagingService {
  AuthorizationStatus statut;
  _MessagingFake(this.statut);

  @override
  Future<NotificationSettings> requestPermission() async =>
      NotificationSettings(
        alert: AppleNotificationSetting.enabled,
        announcement: AppleNotificationSetting.disabled,
        authorizationStatus: statut,
        badge: AppleNotificationSetting.enabled,
        carPlay: AppleNotificationSetting.disabled,
        lockScreen: AppleNotificationSetting.enabled,
        notificationCenter: AppleNotificationSetting.enabled,
        showPreviews: AppleShowPreviewSetting.always,
        timeSensitive: AppleNotificationSetting.disabled,
        criticalAlert: AppleNotificationSetting.disabled,
        sound: AppleNotificationSetting.enabled,
        providesAppNotificationSettings: AppleNotificationSetting.disabled,
      );

  @override
  Future<String?> getToken({String? vapidKey}) async => 'jeton-appareil';

  @override
  Stream<String> get onTokenRefresh => const Stream.empty();

  @override
  Stream<RemoteMessage> get onForegroundMessage => const Stream.empty();

  @override
  Stream<RemoteMessage> get onMessageOpenedApp => const Stream.empty();

  @override
  Future<RemoteMessage?> getInitialMessage() async => null;
}

class _AppareilsFake implements DeviceRepository {
  final enregistres = <String>[];
  final retires = <String>[];

  @override
  Future<void> register({
    required String token,
    required String plateforme,
  }) async => enregistres.add(token);

  @override
  Future<void> unregister(String token) async => retires.add(token);
}

class _SystemeFake extends NotificationsSysteme {
  bool autorise;
  _SystemeFake(this.autorise);

  @override
  Future<bool> sontAutorisees() async => autorise;
}

void main() {
  late AppPreferencesService preferences;
  late _AppareilsFake appareils;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = AppPreferencesService(await SharedPreferences.getInstance());
    appareils = _AppareilsFake();
  });

  PushService service(AuthorizationStatus statut, {bool telephone = true}) =>
      PushService(
        messaging: _MessagingFake(statut),
        devices: appareils,
        preferences: preferences,
        systeme: _SystemeFake(telephone),
        openTarget: (_) {},
      );

  test(
    'activation autorisée : appareil enregistré, notifications actives',
    () async {
      final push = service(AuthorizationStatus.authorized);

      final resultat = await push.setEnabled(true);

      expect(resultat, ActivationNotifications.active);
      expect(appareils.enregistres, ['jeton-appareil']);
      expect(preferences.isPushEnabled(), isTrue);
      expect(await push.estActif(), isTrue);
    },
  );

  test(
    'autorisation refusée par le téléphone : option désactivée, invitation aux réglages',
    () async {
      final push = service(AuthorizationStatus.denied);

      final resultat = await push.setEnabled(true);

      expect(resultat, ActivationNotifications.refuseeParLeTelephone);
      expect(appareils.enregistres, isEmpty);
      expect(preferences.isPushEnabled(), isFalse);
    },
  );

  test(
    'notifications coupées dans les réglages du téléphone : refusées, état inactif',
    () async {
      final push = service(AuthorizationStatus.authorized, telephone: false);

      expect(
        await push.setEnabled(true),
        ActivationNotifications.refuseeParLeTelephone,
      );
      expect(await push.estActif(), isFalse);
    },
  );

  test('désactivation : l\'appareil est retiré du compte', () async {
    final push = service(AuthorizationStatus.authorized);
    await push.setEnabled(true);

    final resultat = await push.setEnabled(false);

    expect(resultat, ActivationNotifications.desactivee);
    expect(appareils.retires, ['jeton-appareil']);
    expect(await push.estActif(), isFalse);
  });
}
