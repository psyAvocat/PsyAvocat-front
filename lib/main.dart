import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/config/app_config.dart';
import 'core/services/app_preferences_service.dart';
import 'core/services/firebase_messaging_service.dart';
import 'core/config/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/universe_provider.dart';
import 'core/widgets/widgets.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisation de Firebase avec la configuration multi-plateforme (Android, iOS, Web)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialisation des préférences locales
  final sharedPreferences = await SharedPreferences.getInstance();

  // Enregistrement du handler d'arrière-plan FCM sur mobile
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  runApp(
    ProviderScope(
      // Pas de nouvelle tentative automatique en cas d'erreur API : l'écran
      // affiche immédiatement l'erreur et l'utilisateur choisit de « Réessayer ».
      retry: (retryCount, error) => null,
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const PsyAvocatApp(),
    ),
  );
}

class PsyAvocatApp extends ConsumerWidget {
  const PsyAvocatApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final universe = ref.watch(currentUniverseProvider);

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: AppNotification.messengerKey,
      theme: AppTheme.buildTheme(universe),
      routerConfig: router,
    );
  }
}
