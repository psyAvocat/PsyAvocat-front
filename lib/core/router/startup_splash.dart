import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Le splash (logo sur fond blanc) s'affiche une seule fois, à l'ouverture de
/// l'application, pendant au moins [minimum]. Il n'apparaît jamais ensuite au
/// milieu du parcours (connexion, revérification de la session…).
/// Ensuite, il reste affiché tant que la session se vérifie, et propose
/// « Réessayer » si le serveur est injoignable (voir SplashScreen).
///
/// `true` une fois cette durée écoulée.
class StartupSplashNotifier extends Notifier<bool> {
  static const minimum = Duration(seconds: 3);

  @override
  bool build() {
    final timer = Timer(minimum, () => state = true);
    ref.onDispose(timer.cancel);
    return false;
  }
}

final startupSplashDoneProvider = NotifierProvider<StartupSplashNotifier, bool>(
  StartupSplashNotifier.new,
);
