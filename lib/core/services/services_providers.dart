import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_auth_service.dart';
import 'firebase_messaging_service.dart';

/// Provider pour le service Firebase Authentication
final firebaseAuthServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
});

/// Provider pour le service Firebase Cloud Messaging
final firebaseMessagingServiceProvider =
    Provider<FirebaseMessagingService>((ref) {
  return FirebaseMessagingService();
});

/// StreamProvider pour observer le renouvellement du jeton FCM
final fcmTokenRefreshProvider = StreamProvider<String>((ref) {
  final messagingService = ref.watch(firebaseMessagingServiceProvider);
  return messagingService.onTokenRefresh;
});

/// StreamProvider pour les notifications reçues au premier plan (Foreground)
final fcmForegroundMessageProvider = StreamProvider<RemoteMessage>((ref) {
  final messagingService = ref.watch(firebaseMessagingServiceProvider);
  return messagingService.onForegroundMessage;
});

/// StreamProvider pour les notifications ouvertes depuis l'arrière-plan
final fcmMessageOpenedAppProvider = StreamProvider<RemoteMessage>((ref) {
  final messagingService = ref.watch(firebaseMessagingServiceProvider);
  return messagingService.onMessageOpenedApp;
});
