import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Notifications au niveau du téléphone (Android / iOS) : autorisation réelle
/// accordée à l'application et accès à ses réglages de notifications.
///
/// Pont natif : MainActivity.kt (Android) et AppDelegate.swift (iOS).
class NotificationsSysteme {
  static const _canal = MethodChannel('psyavocat/notifications');

  const NotificationsSysteme();

  /// Vrai si le téléphone autorise l'application à afficher des notifications.
  /// En cas de doute (plateforme non prise en charge), on ne bloque pas.
  Future<bool> sontAutorisees() async {
    if (kIsWeb) return true;
    try {
      return await _canal.invokeMethod<bool>('areNotificationsEnabled') ?? true;
    } on MissingPluginException {
      return true;
    } on PlatformException {
      return true;
    }
  }

  /// Ouvre les réglages de notifications de l'application dans le téléphone.
  Future<void> ouvrirReglages() async {
    if (kIsWeb) return;
    try {
      await _canal.invokeMethod<void>('openNotificationSettings');
    } on MissingPluginException {
      // Plateforme sans réglages dédiés : rien à ouvrir.
    } on PlatformException {
      // Réglages indisponibles sur cet appareil.
    }
  }
}

final notificationsSystemeProvider = Provider<NotificationsSysteme>(
  (ref) => const NotificationsSysteme(),
);
