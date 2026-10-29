import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/app_preferences_service.dart';
import '../../auth/presentation/controllers/session_controller.dart';
import '../../profile/data/repositories/profil_repository.dart';
import '../../profile/presentation/controllers/profil_controller.dart';

/// Visite guidée de l'application : proposée une seule fois par compte, à la
/// première arrivée sur l'accueil.
///
/// « Déjà vue » est enregistré sur le compte (serveur), donc valable sur tous
/// les appareils et après une réinstallation ; une copie locale, par compte,
/// évite de la reproposer si le serveur n'a pas pu être prévenu.
/// Elle peut être relancée à la demande depuis les Paramètres.
final visiteGuideeProvider = NotifierProvider<VisiteGuideeNotifier, bool>(
  VisiteGuideeNotifier.new,
);

/// Relance demandée depuis les Paramètres (indépendante du « déjà vue »).
final _visiteRelanceeProvider = NotifierProvider<_VisiteRelancee, bool>(
  _VisiteRelancee.new,
);

class _VisiteRelancee extends Notifier<bool> {
  @override
  bool build() => false;

  void definir(bool valeur) => state = valeur;
}

class VisiteGuideeNotifier extends Notifier<bool> {
  @override
  bool build() {
    final compte = ref.watch(signedInAccountProvider);
    if (compte == null) return false;
    if (ref.watch(_visiteRelanceeProvider)) return true;
    final profil = ref.watch(currentProfilProvider).value;
    if (profil == null || profil.visiteGuideeVue) return false;
    return !ref.read(appPreferencesServiceProvider).visiteGuideeVue(compte);
  }

  /// Relance la visite depuis le début (Paramètres).
  void relancer() => ref.read(_visiteRelanceeProvider.notifier).definir(true);

  /// Visite terminée ou passée : elle ne sera plus proposée à ce compte.
  Future<void> terminer() async {
    ref.read(_visiteRelanceeProvider.notifier).definir(false);
    state = false;
    final compte = ref.read(signedInAccountProvider);
    if (compte == null) return;
    await ref.read(appPreferencesServiceProvider).setVisiteGuideeVue(compte);
    try {
      await ref.read(profilRepositoryProvider).marquerVisiteGuideeVue();
    } catch (_) {
      // Hors ligne : la copie locale suffit sur cet appareil.
    }
  }
}
