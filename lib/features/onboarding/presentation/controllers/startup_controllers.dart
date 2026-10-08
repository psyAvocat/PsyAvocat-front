import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/app_preferences_service.dart';

/// Onboarding déjà vu sur cet appareil (préférence locale, jamais une autorisation).
class OnboardingCompletedNotifier extends Notifier<bool> {
  @override
  bool build() => ref.watch(appPreferencesServiceProvider).hasSeenOnboarding();

  Future<void> complete() async {
    await ref.read(appPreferencesServiceProvider).setHasSeenOnboarding(true);
    state = true;
  }
}

final onboardingCompletedProvider =
    NotifierProvider<OnboardingCompletedNotifier, bool>(OnboardingCompletedNotifier.new);

/// Animation du splash terminée : le routeur ne quitte pas le splash avant.
class SplashDoneNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void markDone() => state = true;
}

final splashDoneProvider = NotifierProvider<SplashDoneNotifier, bool>(SplashDoneNotifier.new);
