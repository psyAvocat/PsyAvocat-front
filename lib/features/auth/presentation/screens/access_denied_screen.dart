import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/design_system.dart';
import '../controllers/session_controller.dart';
import '../utils/auth_navigation.dart';

/// « Accès refusé sur mobile » : affiché quand `GET /me` renvoie un rôle
/// administrateur ou professionnel (ou un compte désactivé).
///
/// La session Firebase est déjà fermée. Le bouton ramène à la connexion :
/// c'est le routeur qui navigue, à partir de l'état de session.
class AccessDeniedScreen extends ConsumerWidget {
  const AccessDeniedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final message =
        ref.watch(sessionControllerProvider).message ??
        professionalAccountMessage;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppSpacing.screenPadding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: scheme.errorContainer,
                  child: Icon(
                    Icons.phonelink_lock_outlined,
                    size: AppIcons.sizeXl - 8,
                    color: scheme.onErrorContainer,
                  ),
                ),
                AppSpacing.vGap24,
                Text(
                  'Accès refusé sur mobile',
                  textAlign: TextAlign.center,
                  style: AppTypography.titreMoyen,
                ),
                AppSpacing.vGap12,
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTypography.texteSecondaire,
                ),
                AppSpacing.vGap32,
                FilledButton(
                  onPressed: () => ref
                      .read(sessionControllerProvider.notifier)
                      .acknowledgeDenied(),
                  child: const Text('Retour à la connexion'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
