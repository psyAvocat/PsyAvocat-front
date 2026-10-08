import 'package:flutter/material.dart';
import '../theme/design_system.dart';

/// Grand titre dont une partie est mise en couleur.
///
/// Exemple :
/// ```dart
/// AppHighlightedTitle(
///   before: 'Prenez soin de votre ',
///   highlight: 'santé mentale',
///   highlightColor: scheme.tertiary,
///   color: Colors.white,
/// )
/// ```
class AppHighlightedTitle extends StatelessWidget {
  final String before;
  final String highlight;
  final String after;
  final Color highlightColor;

  /// Couleur du texte non mis en avant (par défaut : couleur du texte principal).
  final Color? color;

  const AppHighlightedTitle({
    super.key,
    required this.before,
    required this.highlight,
    this.after = '',
    required this.highlightColor,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: AppTypography.grandTitre.copyWith(color: color),
        children: [
          TextSpan(text: before),
          TextSpan(
            text: highlight,
            style: TextStyle(color: highlightColor),
          ),
          if (after.isNotEmpty) TextSpan(text: after),
        ],
      ),
    );
  }
}
