import 'package:flutter/foundation.dart';

/// Configuration globale de l'application PsyAvocat.
///
/// Adresse du serveur Spring Boot, choisie au lancement :
///
/// ```text
/// flutter run                                  émulateur Android (10.0.2.2) ou localhost
/// flutter run --dart-define=ip=192.168.1.20    vrai téléphone : IP du PC sur le même Wi-Fi
/// flutter run --dart-define=ip=localhost       téléphone USB après `adb reverse tcp:8080 tcp:8080`
/// flutter run --dart-define=ip=... --dart-define=port=9090   autre port que 8080
/// ```
class AppConfig {
  AppConfig._();

  /// Nom de l'application
  static const String appName = 'PsyAvocat';

  static const String _ip = String.fromEnvironment('ip');
  static const String _port = String.fromEnvironment(
    'port',
    defaultValue: '8080',
  );

  /// Hôte du serveur : `--dart-define=ip=...`, sinon la machine de développement
  /// vue depuis l'appareil (10.0.2.2 sur l'émulateur Android, localhost ailleurs).
  static String get serverHost {
    final ip = _ip.trim();
    if (ip.isNotEmpty) return ip;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return '10.0.2.2';
    }
    return 'localhost';
  }

  /// URL du serveur Spring Boot (sans le préfixe /api).
  static String get serverBaseUrl => 'http://$serverHost:$_port';

  /// D'où vient [serverHost] (affiché dans les logs au démarrage).
  static String get serverUrlSource {
    if (_ip.trim().isNotEmpty) return '--dart-define=ip';
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'défaut Android (10.0.2.2 = PC hôte, ÉMULATEUR uniquement)';
    }
    return 'défaut (localhost)';
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
