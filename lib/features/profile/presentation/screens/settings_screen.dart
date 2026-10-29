import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/push/notifications_systeme.dart';
import '../../../../core/push/push_service.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/services/app_preferences_service.dart';
import '../../../../core/settings/app_settings.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/theme/universe_provider.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../selection_univers/presentation/widgets/universe_switch_dialog.dart';
import '../widgets/profile_menu.dart';

/// « Paramètres » : espace actif, notifications push sur cet appareil,
/// thème (système, clair, sombre), langue et paiements.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with WidgetsBindingObserver {
  late bool _notifications = ref
      .read(appPreferencesServiceProvider)
      .isPushEnabled();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _rafraichirNotifications();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Retour dans l'application (ex. depuis les réglages du téléphone) : état relu.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _rafraichirNotifications();
  }

  /// L'interrupteur reflète l'état réel : activé ici ET autorisé par le téléphone.
  Future<void> _rafraichirNotifications() async {
    final actif = await ref.read(pushServiceProvider).estActif();
    if (mounted && actif != _notifications) {
      setState(() => _notifications = actif);
    }
  }

  Future<void> _basculerNotifications(bool active) async {
    setState(() => _notifications = active);
    final resultat = await ref.read(pushServiceProvider).setEnabled(active);
    if (!mounted) return;
    switch (resultat) {
      case ActivationNotifications.active:
        setState(() => _notifications = true);
      case ActivationNotifications.desactivee:
        setState(() => _notifications = false);
      case ActivationNotifications.nonPriseEnCharge:
        break;
      case ActivationNotifications.refuseeParLeTelephone:
        setState(() => _notifications = false);
        await _proposerReglagesTelephone();
    }
  }

  /// Notifications bloquées par le téléphone : seul l'utilisateur peut les autoriser.
  Future<void> _proposerReglagesTelephone() async {
    final ouvrir = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('Notifications désactivées sur le téléphone')),
        content: Text(
          tr(
            'Pour recevoir vos rappels de rendez-vous et vos messages, même '
            'lorsque l’application est fermée, autorisez les notifications de '
            'PsyAvocat dans les réglages du téléphone.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr('Plus tard')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr('Ouvrir les réglages')),
          ),
        ],
      ),
    );
    if (ouvrir == true) {
      await ref.read(notificationsSystemeProvider).ouvrirReglages();
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
        ],
      ),
    );
  }
}
