import 'package:flutter/foundation.dart';

/// Configuration globale de l'application PsyAvocat.
class AppConfig {
  AppConfig._();

  /// Nom de l'application
  static const String appName = 'PsyAvocat';

  /// URL de base de l'API Spring Boot
  /// Sur émulateur Android : 10.0.2.2 pointe vers la machine hôte.
  /// Sur Web / Desktop : localhost.
  static String get apiBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080/api';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8080/api';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      default:
        return 'http://localhost:8080/api';
    }
  }

  /// Délais d'expiration des requêtes HTTP
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration sendTimeout = Duration(seconds: 15);
}
