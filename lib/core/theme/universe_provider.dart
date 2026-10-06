import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/app_preferences_service.dart';
import 'app_universe.dart';

/// Notifier Riverpod pour piloter l'univers actif de l'application PsyAvocat.
/// Permet la mutation réactive immédiate du thème et des couleurs de l'application.
class UniverseNotifier extends Notifier<AppUniverse> {
  @override
  AppUniverse build() {
    // Tente de restaurer l'univers mémorisé, sinon reste neutre
    try {
      final prefs = ref.watch(appPreferencesServiceProvider);
      return prefs.getSelectedUniverse() ?? AppUniverse.neutral;
    } catch (_) {
      return AppUniverse.neutral;
    }
  }

  /// Change l'univers actif et le persiste
  Future<void> setUniverse(AppUniverse universe) async {
    state = universe;
    try {
      final prefs = ref.read(appPreferencesServiceProvider);
      await prefs.setSelectedUniverse(universe);
    } catch (_) {}
  }

  /// Réinitialise l'univers au mode neutre (gradient de transition)
  Future<void> resetToNeutral() async {
    state = AppUniverse.neutral;
  }
}

/// Provider global de l'univers actif
final currentUniverseProvider = NotifierProvider<UniverseNotifier, AppUniverse>(
  UniverseNotifier.new,
);
