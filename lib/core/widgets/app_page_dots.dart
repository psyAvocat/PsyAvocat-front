import 'package:flutter/material.dart';
import '../../core/l10n/app_strings.dart';

/// Petits points indiquant la page courante d'un carrousel.
///
/// Exemple : `AppPageDots(count: 2, activeIndex: 0, color: Colors.white)`.
class AppPageDots extends StatelessWidget {
  final int count;
  final int activeIndex;
  final Color color;

  const AppPageDots({
    super.key,
    required this.count,
    required this.activeIndex,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: tr('Page {n} sur {total}', {'n': activeIndex + 1, 'total': count}),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i == activeIndex ? color : color.withValues(alpha: 0.35),
              ),
            ),
        ],
      ),
    );
  }
}
