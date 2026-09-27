import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../../firebase_options.dart';
import '../config/app_config.dart';

/// Handler de messages en arrière-plan pour FCM (Android & iOS).
/// Doit être une fonction de premier niveau annotée avec @pragma('vm:entry-point').
/// Note : Sur le Web, les messages en arrière-plan sont gérés par web/firebase-messaging-sw.js.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('FCM Background Message ID: ${message.messageId}');
}

/// Service complet de gestion de Firebase Cloud Messaging (FCM).
/// Plateformes supportées : Android, iOS, Web.
class FirebaseMessagingService {
  final FirebaseMessaging _messaging;

  FirebaseMessagingService({FirebaseMessaging? messaging})
      : _messaging = messaging ?? FirebaseMessaging.instance;

  /// Demande explicite de permission pour les notifications.
  /// RÈGLE : Ne jamais appeler automatiquement au démarrage sans action utilisateur.
  Future<NotificationSettings> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint(
      'FCM Permission Status: ${settings.authorizationStatus}',
    );
    return settings;
  }

  /// Récupération du jeton FCM de l'appareil.
  /// - Sur iOS : vérifie au préalable la disponibilité de l'APNs token.
  /// - Sur Web : utilise la clé VAPID publique si configurée.
  /// Sécurité : Ne jamais logger ni exposer la valeur brute du token.
  Future<String?> getToken({String? vapidKey}) async {
    try {
      // 1. Vérification spécifique Apple (iOS / macOS)
      if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.iOS ||
              defaultTargetPlatform == TargetPlatform.macOS)) {
        final apnsToken = await _messaging.getAPNSToken();
        if (apnsToken == null) {
          debugPrint(
            'FCM iOS: Le token APNs n\'est pas encore disponible. Réessayer ultérieurement.',
          );
          return null;
        }
      }

      // 2. Détermination de la clé VAPID pour le Web
      String? webVapidKey;
      if (kIsWeb) {
        final keyCandidate = vapidKey ?? AppConfig.fcmWebVapidKey;
        if (keyCandidate.isNotEmpty) {
          webVapidKey = keyCandidate;
        } else {
          debugPrint(
            'FCM Web: Clé VAPID non renseignée dans AppConfig.fcmWebVapidKey. '
            'Veuillez générer une paire de clés dans Firebase Console > Cloud Messaging > Web Push certificates.',
          );
        }
      }

      // 3. Récupération effective du token
      final token = await _messaging.getToken(
        vapidKey: webVapidKey,
      );

      if (token != null) {
        debugPrint('FCM: Token généré avec succès (non affiché pour sécurité).');
      }
      return token;
    } catch (e) {
      debugPrint('FCM Error getting token: $e');
      return null;
    }
  }

  /// Suppression du token FCM (par exemple lors de la déconnexion)
  Future<void> deleteToken() async {
    await _messaging.deleteToken();
  }

  /// Flux de rafraîchissement automatique du token FCM
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  /// Flux de messages reçus lorsque l'application est au premier plan (Foreground)
  Stream<RemoteMessage> get onForegroundMessage => FirebaseMessaging.onMessage;

  /// Flux d'événements lorsqu'une notification est cliquée depuis l'arrière-plan (Background -> Foreground)
  Stream<RemoteMessage> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp;

  /// Vérifie si l'application a été initialement lancée suite au clic sur une notification (Terminated -> Foreground)
  Future<RemoteMessage?> getInitialMessage() async {
    return await _messaging.getInitialMessage();
  }

  /// Inscription à un sujet FCM (Topic)
  Future<void> subscribeToTopic(String topic) async {
    if (!kIsWeb) {
      await _messaging.subscribeToTopic(topic);
    }
  }

  /// Désinscription d'un sujet FCM (Topic)
  Future<void> unsubscribeFromTopic(String topic) async {
    if (!kIsWeb) {
      await _messaging.unsubscribeFromTopic(topic);
    }
  }
}
