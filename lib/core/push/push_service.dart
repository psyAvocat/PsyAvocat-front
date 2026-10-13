import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/controllers/session_controller.dart';
import '../navigation/deep_link.dart';
import '../services/app_preferences_service.dart';
import '../services/firebase_messaging_service.dart';
import '../widgets/app_alert.dart';
import 'device_repository.dart';

/// Notifications push du compte sur cet appareil.
///
/// - Les push sont globaux au compte : un rendez-vous Avocat est reçu même
///   depuis l'univers Psychologue (le tap propose alors de changer d'univers).
/// - Le jeton n'est enregistré qu'une fois la session autorisée et si
///   l'utilisateur n'a pas désactivé les notifications dans les paramètres.
/// - Il est retiré du serveur AVANT la déconnexion Firebase.
class PushService {
  final FirebaseMessagingService _messaging;
  final DeviceRepository _devices;
  final AppPreferencesService _preferences;
  final void Function(DeepLinkTarget target) _openTarget;

  final List<StreamSubscription<Object?>> _subscriptions = [];
  String? _registeredToken;
  bool _listening = false;

  PushService({
    required FirebaseMessagingService messaging,
    required DeviceRepository devices,
    required AppPreferencesService preferences,
    required void Function(DeepLinkTarget target) openTarget,
  }) : _messaging = messaging,
       _devices = devices,
       _preferences = preferences,
       _openTarget = openTarget;

  /// Plateforme attendue par le backend ; null si non prise en charge.
  static String? get platformName {
    if (kIsWeb) return 'WEB';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'ANDROID';
      case TargetPlatform.iOS:
        return 'IOS';
      default:
        return null;
    }
  }

  bool get isSupported => platformName != null;

  /// Appelé quand la session devient autorisée.
  Future<void> onAuthorized() async {
    if (!isSupported) return;
    _listenOnce();
    if (_preferences.isPushEnabled()) await _register();
  }

  /// Active ou désactive la réception sur cet appareil (Paramètres).
  Future<void> setEnabled(bool enabled) async {
    await _preferences.setPushEnabled(enabled);
    if (!isSupported) return;
    if (enabled) {
      await _register();
    } else {
      await unregister();
    }
  }

  /// Retire l'appareil du compte (avant déconnexion ou sur désactivation).
  Future<void> unregister() async {
    final token = _registeredToken;
    _registeredToken = null;
    if (token == null) return;
    try {
      await _devices.unregister(token);
    } catch (_) {
      // Le serveur désactivera de lui-même un jeton devenu invalide.
    }
  }

  Future<void> _register() async {
    try {
      final settings = await _messaging.requestPermission();
      final status = settings.authorizationStatus;
      if (status != AuthorizationStatus.authorized &&
          status != AuthorizationStatus.provisional) {
        return;
      }
      final token = await _messaging.getToken();
      if (token != null) await _sendToken(token);
    } catch (_) {
      debugPrint('Push: enregistrement de l\'appareil impossible.');
    }
  }

  Future<void> _sendToken(String token) async {
    await _devices.register(token: token, plateforme: platformName!);
    _registeredToken = token;
  }

  void _listenOnce() {
    if (_listening) return;
    _listening = true;
    try {
      _subscriptions.add(
        _messaging.onTokenRefresh.listen((token) {
          if (_registeredToken != null && _preferences.isPushEnabled()) {
            _sendToken(token).catchError((_) {});
          }
        }),
      );
      _subscriptions.add(
        _messaging.onForegroundMessage.listen(_showForeground),
      );
      _subscriptions.add(
        _messaging.onMessageOpenedApp.listen(_openFromMessage),
      );
      _messaging
          .getInitialMessage()
          .then((message) {
            if (message != null) _openFromMessage(message);
          })
          .catchError((_) {});
    } catch (_) {
      debugPrint('Push: Firebase Messaging indisponible sur cette plateforme.');
    }
  }

  /// Application au premier plan : bannière discrète avec accès direct.
  void _showForeground(RemoteMessage message) {
    final notification = message.notification;
    final text = notification?.body ?? notification?.title;
    if (text == null || text.isEmpty) return;
    final target = DeepLinkTarget.fromData(message.data);
    AppNotification.showInfo(
      null,
      notification?.title != null && notification?.body != null
          ? '${notification!.title} — ${notification.body}'
          : text,
      actionLabel: 'Voir',
      onAction: () => _openTarget(target),
    );
  }

  void _openFromMessage(RemoteMessage message) {
    _openTarget(DeepLinkTarget.fromData(message.data));
  }

  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
  }
}

final pushServiceProvider = Provider<PushService>((ref) {
  final service = PushService(
    messaging: ref.watch(firebaseMessagingServiceProvider),
    devices: ref.watch(deviceRepositoryProvider),
    preferences: ref.watch(appPreferencesServiceProvider),
    openTarget: (target) =>
        ref.read(pendingDeepLinkProvider.notifier).push(target),
  );
  ref.listen<SessionState>(sessionControllerProvider, (previous, session) {
    if (session.isAuthorized && previous?.isAuthorized != true) {
      service.onAuthorized();
    }
  }, fireImmediately: true);
  ref.onDispose(service.dispose);
  return service;
});
