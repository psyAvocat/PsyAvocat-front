import 'package:flutter/material.dart';
import '../theme/design_system.dart';
import 'app_progress_bar.dart';

/// Indicateur de chargement centralisé harmonisé avec le Design System.
class AppLoadingIndicator extends StatelessWidget {
  final String? message;
  final AppUniverse? universe;

  const AppLoadingIndicator({
    super.key,
    this.message,
    this.universe,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppCircularProgress(
            size: 32,
            strokeWidth: 3,
            universe: universe,
          ),
          if (message != null) ...[
            AppSpacing.vGap16,
            Text(
              message!,
              textAlign: TextAlign.center,
              style: AppTypography.texteSecondaire.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
