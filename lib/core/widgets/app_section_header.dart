import 'package:flutter/material.dart';
import '../theme/design_system.dart';

/// Titre de section, avec un lien optionnel à droite (« Voir tout »).
///
/// Exemple : `AppSectionHeader(title: 'Avocats', actionLabel: 'Voir tout', onAction: ...)`
class AppSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTypography.petitTitre.copyWith(fontSize: 18),
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}
