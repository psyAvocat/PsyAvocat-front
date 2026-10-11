import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_universe.dart';
import '../../../../core/theme/universe_provider.dart';
import '../../../../core/widgets/app_button.dart';

/// Demande confirmation puis bascule vers l'autre univers.
///
/// Après confirmation : thème, navigation et données suivent le nouvel
/// univers (tous les providers dépendent de `currentUniverseProvider`).
Future<void> confirmUniverseSwitch(BuildContext context, WidgetRef ref) async {
  final current = ref.read(currentUniverseProvider);
  final target = current.isPsychologist
      ? AppUniverse.lawyer
      : AppUniverse.psychologist;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: Icon(
        target.isPsychologist
            ? Icons.psychology_outlined
            : Icons.balance_outlined,
      ),
      title: Text('Passer à l’espace ${target.displayName} ?'),
      content: Text(
        'Vous quitterez l’espace ${current.displayName}. Vos rendez-vous et '
        'vos rappels restent conservés.',
      ),
      actions: [
        AppButton.ghost(
          text: 'Annuler',
          onPressed: () => Navigator.of(dialogContext).pop(false),
        ),
        AppButton(
          text: 'Continuer',
          isFullWidth: false,
          size: AppButtonSize.compact,
          onPressed: () => Navigator.of(dialogContext).pop(true),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    await ref.read(currentUniverseProvider.notifier).setUniverse(target);
  }
}
