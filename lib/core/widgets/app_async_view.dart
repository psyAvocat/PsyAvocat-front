import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../errors/user_message.dart';
import '../theme/design_system.dart';
import 'app_state_views.dart';

/// Affiche les 4 états d'une donnée chargée depuis l'API :
/// LOADING → indicateur, ERROR → message + « Réessayer »,
/// EMPTY → message d'état vide, SUCCESS → [builder].
///
/// [compact] : version discrète pour une section d'écran (ex. une carte de l'accueil).
///
/// Exemple :
/// ```dart
/// AppAsyncView<List<Pro>>(
///   value: ref.watch(prosProvider),
///   isEmpty: (pros) => pros.isEmpty,
///   emptyMessage: 'Aucun avocat disponible pour le moment.',
///   onRetry: () => ref.invalidate(prosProvider),
///   builder: (pros) => ProList(pros),
/// )
/// ```
class AppAsyncView<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final bool Function(T data)? isEmpty;
  final String emptyTitle;
  final String? emptyMessage;
  final IconData emptyIcon;
  final VoidCallback? onRetry;
  final bool compact;

  const AppAsyncView({
    super.key,
    required this.value,
    required this.builder,
    this.isEmpty,
    this.emptyTitle = 'Rien à afficher',
    this.emptyMessage,
    this.emptyIcon = Icons.inbox_outlined,
    this.onRetry,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    // Après « Réessayer », on montre le chargement plutôt que l'ancienne erreur.
    if (value.isLoading && value.hasError) return _buildLoading();

    return value.when(
      // On garde les données affichées pendant un rafraîchissement.
      skipLoadingOnRefresh: true,
      loading: _buildLoading,
      error: (error, _) {
        final message = userMessageFor(error);
        if (compact) {
          return _InlineMessage(
            icon: AppIcons.danger,
            message: message,
            actionLabel: onRetry == null ? null : 'Réessayer',
            onAction: onRetry,
            isError: true,
          );
        }
        return AppErrorStateView(
          title: 'Chargement impossible',
          message: message,
          onRetry: onRetry,
        );
      },
      data: (data) {
        if (isEmpty?.call(data) ?? false) {
          if (compact) {
            return _InlineMessage(
              icon: emptyIcon,
              message: emptyMessage ?? emptyTitle,
            );
          }
          return AppEmptyStateView(
            title: emptyTitle,
            message: emptyMessage,
            icon: emptyIcon,
          );
        }
        return builder(data);
      },
    );
  }

  Widget _buildLoading() {
    return compact
        ? const _CompactBox(child: CircularProgressIndicator())
        : const AppLoadingView(message: 'Chargement…');
  }
}

class _CompactBox extends StatelessWidget {
  final Widget child;

  const _CompactBox({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.paddingAll24,
      child: Center(child: child),
    );
  }
}

/// Message court dans une carte (état vide ou erreur d'une section).
class _InlineMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isError;

  const _InlineMessage({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = isError ? scheme.error : scheme.onSurfaceVariant;

    return Card(
      child: Padding(
        padding: AppSpacing.cardPaddingCompact,
        child: Row(
          children: [
            Icon(icon, color: color),
            AppSpacing.hGap12,
            Expanded(
              child: Text(
                message,
                style: AppTypography.texteSecondaire.copyWith(color: color),
              ),
            ),
            if (actionLabel != null && onAction != null)
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ),
      ),
    );
  }
}
