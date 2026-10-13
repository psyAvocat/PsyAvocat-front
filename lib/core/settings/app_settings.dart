import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_strings.dart';
import '../services/app_preferences_service.dart';

/// Réglages d'affichage de l'appareil : thème et langue.
class AppSettings {
  final ThemeMode themeMode;
  final Locale locale;

  const AppSettings({required this.themeMode, required this.locale});

  bool get isEnglish => locale.languageCode == 'en';
}

ThemeMode _themeModeFrom(String value) => switch (value) {
  'light' => ThemeMode.light,
  'dark' => ThemeMode.dark,
  _ => ThemeMode.system,
};

/// Thème (système, clair, sombre) et langue (français, anglais), mémorisés
/// sur l'appareil et appliqués immédiatement à toute l'application.
class AppSettingsNotifier extends Notifier<AppSettings> {
  AppPreferencesService get _prefs => ref.read(appPreferencesServiceProvider);

  @override
  AppSettings build() {
    final prefs = ref.watch(appPreferencesServiceProvider);
    final langue = prefs.language();
    setAppLanguage(langue);
    return AppSettings(
      themeMode: _themeModeFrom(prefs.themeMode()),
      locale: langue == 'en' ? const Locale('en') : const Locale('fr', 'FR'),
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = AppSettings(themeMode: mode, locale: state.locale);
    await _prefs.setThemeMode(mode.name);
  }

  Future<void> setLanguage(String code) async {
    setAppLanguage(code);
    state = AppSettings(
      themeMode: state.themeMode,
      locale: code == 'en' ? const Locale('en') : const Locale('fr', 'FR'),
    );
    await _prefs.setLanguage(code);
  }
}

final appSettingsProvider = NotifierProvider<AppSettingsNotifier, AppSettings>(
  AppSettingsNotifier.new,
);
