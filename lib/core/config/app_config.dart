import 'package:flutter/foundation.dart';

/// Configuration globale de l'application PsyAvocat.
class AppConfig {
  AppConfig._();

  /// Nom de l'application
  static const String appName = 'PsyAvocat';

  /// URL du serveur Spring Boot (sans le préfixe /api).
  /// Sur émulateur Android : 10.0.2.2 pointe vers la machine hôte.
  /// Sur Web / Desktop / iOS : localhost.
  static String get serverBaseUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }

  /// URL de base de l'API REST métier (/api/...).
  static String get apiBaseUrl => '$serverBaseUrl/api';

  /// Endpoint de session : exposé à la racine du serveur (GET /me), pas sous /api.
  static String get meUrl => '$serverBaseUrl/me';

  /// Délais d'expiration des requêtes HTTP
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration sendTimeout = Duration(seconds: 15);

  /// Clé publique VAPID (Web Push Certificate) pour Firebase Cloud Messaging sur le Web.
  /// Générée sur Firebase Console > Paramètres du projet > Cloud Messaging > Certificats Web Push.
  static const String fcmWebVapidKey =
      'BCpeMgUwUuUl4cj1B-OcqbubArUauW2UlpMX0qEzuearqM2j0hNZ0wora1IAsL-wqlwVQeSOgRaVOnYib3HPDd4';
}
