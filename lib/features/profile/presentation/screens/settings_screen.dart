import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/push/push_service.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/services/app_preferences_service.dart';
import '../../../../core/settings/app_settings.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/theme/universe_provider.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../onboarding/presentation/widgets/first_use_tutorial_overlay.dart';
import '../../../selection_univers/presentation/widgets/universe_switch_dialog.dart';
import '../widgets/profile_menu.dart';

/// « Paramètres » : espace actif, notifications push sur cet appareil,
/// thème (système, clair, sombre), langue et paiements.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late bool _notifications = ref
      .read(appPreferencesServiceProvider)
      .isPushEnabled();

  Future<void> _basculerNotifications(bool active) async {
    setState(() => _notifications = active);
    try {
      await ref.read(pushServiceProvider).setEnabled(active);
    } catch (_) {
      // Push indisponible sur cette plateforme : seule la préférence est gardée.
      await ref.read(appPreferencesServiceProvider).setPushEnabled(active);
    }
  }

  String _libelleTheme(ThemeMode mode) => switch (mode) {
    ThemeMode.light => tr('Clair'),
    ThemeMode.dark => tr('Sombre'),
    ThemeMode.system => tr('Comme le téléphone'),
  };

  Future<void> _choisirTheme(ThemeMode actuel) async {
    final choix = await _choisir<ThemeMode>(
      titre: tr('Thème'),
      valeur: actuel,
      options: {
        for (final mode in [ThemeMode.system, ThemeMode.light, ThemeMode.dark])
          mode: _libelleTheme(mode),
      },
    );
    if (choix != null) {
      await ref.read(appSettingsProvider.notifier).setThemeMode(choix);
    }
  }

  Future<void> _choisirLangue(String actuelle) async {
    final choix = await _choisir<String>(
      titre: tr('Langue'),
      valeur: actuelle,
      options: const {'fr': 'Français', 'en': 'English'},
    );
    if (choix != null) {
      await ref.read(appSettingsProvider.notifier).setLanguage(choix);
    }
  }

  /// Liste de choix en bas de l'écran ; renvoie la valeur choisie.
  Future<T?> _choisir<T>({
    required String titre,
    required T valeur,
    required Map<T, String> options,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(titre, style: AppTypography.petitTitre),
            ),
            for (final option in options.entries)
              ListTile(
                title: Text(option.value),
                trailing: option.key == valeur
                    ? Icon(Icons.check_rounded, color: context.colors.primary)
                    : null,
                onTap: () => Navigator.pop(context, option.key),
              ),
            AppSpacing.vGap8,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final universe = ref.watch(currentUniverseProvider);
    final settings = ref.watch(appSettingsProvider);

    return Scaffold(
      backgroundColor: context.palette.card,
      appBar: AppPageHeader(title: tr('Paramètres')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        children: [
          ProfileSectionTitle(tr('Préférences')),
          ProfileMenuItem(
            icon: Icons.swap_horiz_rounded,
            label: universe.isPsychologist
                ? tr('Passer à l’espace Avocat')
                : tr('Passer à l’espace Psychologue'),
            onTap: () => confirmUniverseSwitch(context, ref),
          ),
          ProfileMenuItem(
            icon: Icons.notifications_none_rounded,
            label: tr('Notifications'),
            onTap: () => _basculerNotifications(!_notifications),
            trailing: Switch.adaptive(
              value: _notifications,
              activeTrackColor: context.colors.primary,
              onChanged: _basculerNotifications,
            ),
          ),
          ProfileMenuItem(
            icon: Icons.dark_mode_outlined,
            label: tr('Thème'),
            value: _libelleTheme(settings.themeMode),
            onTap: () => _choisirTheme(settings.themeMode),
          ),
          ProfileMenuItem(
            icon: Icons.translate_rounded,
            label: tr('Langue'),
            value: settings.isEnglish ? 'English' : 'Français',
            onTap: () => _choisirLangue(settings.locale.languageCode),
          ),
          ProfileSectionTitle(tr('Mon activité')),
          ProfileMenuItem(
            icon: Icons.receipt_long_outlined,
            label: tr('Mes paiements'),
            onTap: () => context.push(AppRoutes.paiements),
          ),
          ProfileMenuItem(
            icon: Icons.auto_awesome_outlined,
            label: tr('Revoir le tutoriel de première utilisation'),
            onTap: () async {
              await ref
                  .read(showTutorialOverlayProvider.notifier)
                  .startTutorial();
              if (context.mounted) {
                context.go(AppRoutes.home);
              }
            },
          ),
        ],
      ),
    );
  }
}
