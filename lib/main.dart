import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/app_config.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisation de Firebase avec la configuration multi-plateforme (Android, iOS, Web)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ProviderScope(child: PsyAvocatApp()));
}

class PsyAvocatApp extends ConsumerWidget {
  const PsyAvocatApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ;

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
    );
  }
}
