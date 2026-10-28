import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/config/app_config.dart';
import 'core/l10n/app_strings.dart';
import 'core/settings/app_settings.dart';
import 'core/network/api_logger_interceptor.dart';
import 'core/services/app_preferences_service.dart';
import 'core/services/firebase_messaging_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/universe_provider.dart';
import 'core/widgets/widgets.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configuration réseau utilisée (visible dans la console `flutter run`).
  apiLog(
    'Serveur backend : ${AppConfig.serverBaseUrl} '
    '(source : ${AppConfig.serverUrlSource})',
  );
  apiLog(
    'Délais : connexion ${AppConfig.connectTimeout.inSeconds} s, '
    'réponse ${AppConfig.receiveTimeout.inSeconds} s',
  );

  // Initialisation de Firebase avec la configuration multi-plateforme (Android, iOS, Web)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialisation des préférences locales
  final sharedPreferences = await SharedPreferences.getInstance();

  // Noms des mois et des jours (DateFormat) : sans cette initialisation,
  // `DateFormat('MMM')` lève une LocaleDataException dès qu'un rendez-vous
  // s'affiche (accueil « Prochain rendez-vous », page Rendez-vous).
  await initializeDateFormatting();
  setAppLanguage(AppPreferencesService(sharedPreferences).language());

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
    final settings = ref.watch(appSettingsProvider);

    // Changement de langue : tous les écrans relisent leurs textes.
    ref.listen(appSettingsProvider.select((s) => s.locale), (_, _) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) rebuildAllChildren(context);
      });
    });

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: AppNotification.messengerKey,
      theme: AppTheme.buildTheme(universe),
      darkTheme: AppTheme.buildTheme(universe, brightness: Brightness.dark),
      themeMode: settings.themeMode,
      locale: settings.locale,
      supportedLocales: supportedAppLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: router,
      builder: (context, child) => TooltipVisibility(
        visible: false,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
