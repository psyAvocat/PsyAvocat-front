import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/app_preferences_service.dart';

/// Thème clair / sombre / système, appliqué à toute l'application et mémorisé
/// sur l'appareil (préférence locale, pas une donnée métier).
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ref.watch(appPreferencesServiceProvider).getThemeMode();

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await ref.read(appPreferencesServiceProvider).setThemeMode(mode);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);
