import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Le splash (logo sur fond blanc) s'affiche une seule fois, à l'ouverture de
/// l'application, pendant au moins [minimum]. Il n'apparaît jamais ensuite au
/// milieu du parcours (connexion, revérification de la session…).
///
/// `true` une fois cette durée écoulée.
class StartupSplashNotifier extends Notifier<bool> {
  static const minimum = Duration(milliseconds: 1800);

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
