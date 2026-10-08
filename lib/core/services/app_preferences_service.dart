import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_universe.dart';

/// Préférences LOCALES de l'appareil (jamais des données métier ni des autorisations) :
/// onboarding vu, dernier univers affiché, thème, réception des notifications push.
class AppPreferencesService {
  static const String _keyHasSeenOnboarding = 'has_seen_onboarding';
  static const String _keySelectedUniverse = 'selected_universe';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyPushEnabled = 'push_enabled';

  final SharedPreferences _prefs;

  AppPreferencesService(this._prefs);

  /// Vérifie si l'utilisateur a déjà complété l'onboarding
  bool hasSeenOnboarding() {
    return _prefs.getBool(_keyHasSeenOnboarding) ?? false;
  }

  /// Marque l'onboarding comme complété
  Future<void> setHasSeenOnboarding(bool value) async {
    await _prefs.setBool(_keyHasSeenOnboarding, value);
  }

  /// Récupère l'univers mémorisé
  AppUniverse? getSelectedUniverse() {
    final str = _prefs.getString(_keySelectedUniverse);
    if (str == null) return null;
    if (str == AppUniverse.lawyer.name) return AppUniverse.lawyer;
    if (str == AppUniverse.psychologist.name) return AppUniverse.psychologist;
    return AppUniverse.neutral;
  }

  /// Mémorise l'univers sélectionné
  Future<void> setSelectedUniverse(AppUniverse universe) async {
    await _prefs.setString(_keySelectedUniverse, universe.name);
  }

  /// Oublie l'univers affiché (déconnexion : le prochain utilisateur choisit le sien).
  Future<void> clearSelectedUniverse() async {
    await _prefs.remove(_keySelectedUniverse);
  }

  /// Thème choisi : clair, sombre ou celui du système (par défaut).
  ThemeMode getThemeMode() {
    final value = _prefs.getString(_keyThemeMode);
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setString(_keyThemeMode, mode.name);
  }

  /// Réception des notifications push sur cet appareil (activée par défaut).
  bool isPushEnabled() => _prefs.getBool(_keyPushEnabled) ?? true;

  Future<void> setPushEnabled(bool enabled) async {
    await _prefs.setBool(_keyPushEnabled, enabled);
  }

  /// Réinitialise les préférences locales (utile lors du logout complet ou pour les tests)
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}

/// Provider pour initialiser et accéder à SharedPreferences
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider doit être initialisé dans main.dart via overrideWithValue',
  );
});

final appPreferencesServiceProvider = Provider<AppPreferencesService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AppPreferencesService(prefs);
});
