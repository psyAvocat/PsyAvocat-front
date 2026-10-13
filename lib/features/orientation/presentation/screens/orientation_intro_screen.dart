import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/l10n/app_strings.dart';

/// Proposition du questionnaire d'orientation, juste après le choix de
/// l'univers Psychologue : facultatif, l'utilisateur peut le passer.
/// (Depuis l'accueil, le bouton « Faire le test » ouvre directement les questions.)
class OrientationIntroScreen extends ConsumerWidget {
  const OrientationIntroScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: AppSpacing.screenPadding,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - AppSpacing.s48,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.go(AppRoutes.home),
                        child: Text(tr('Passer')),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      tr('Trouvons le bon psychologue'),
                      style: AppTypography.grandTitre.copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                    AppSpacing.vGap12,
                    Text(
                      tr(
                        'Quelques questions, moins de 2 minutes.\n'
                        'Ce n’est pas un diagnostic.',
                      ),
                      style: AppTypography.texte.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    const Spacer(flex: 2),
                    AppSpacing.vGap24,
                    AppButton(
                      text: tr('Commencer'),
                      onPressed: () => context.go(AppRoutes.orientation),
                    ),
                    AppSpacing.vGap12,
                    AppButton.outline(
                      text: tr('Plus tard'),
                      onPressed: () => context.go(AppRoutes.home),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
