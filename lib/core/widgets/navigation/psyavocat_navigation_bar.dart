import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'nav_bar_painter.dart';
import 'nav_destination.dart';
import '../../../core/theme/app_palette.dart';

export 'nav_destination.dart';

/// Barre de navigation inférieure animée de PsyAvocat.
///
/// - Capsule blanche flottante, large, aux bords très arrondis.
/// - L'onglet actif se soulève dans un rond de la couleur de l'univers, logé
///   dans une encoche creusée dans la barre (un trou, pas un dôme posé dessus).
/// - L'encoche glisse d'un onglet à l'autre ; le rond se forme autour du
///   nouvel onglet pendant que l'ancien redescend.
/// - Tous les onglets se comportent de la même façon, y compris celui du milieu.
///
/// Les onglets ([destinations]) sont fournis par l'appelant
/// (voir `features/navigation/presentation/navigation_destinations.dart`).
class PsyAvocatNavigationBar extends StatefulWidget {
  final List<NavDestination> destinations;
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  /// Position de l'onglet « Avocats / Psychologues » dans [destinations].
  static const int centralIndex = 2;

  const PsyAvocatNavigationBar({
    super.key,
    required this.destinations,
    required this.currentIndex,
    required this.onDestinationSelected,
  }) : assert(destinations.length == 5, 'La barre attend 5 onglets.');

  @override
  State<PsyAvocatNavigationBar> createState() => _PsyAvocatNavigationBarState();
}

class _PsyAvocatNavigationBarState extends State<PsyAvocatNavigationBar>
    with SingleTickerProviderStateMixin {
  /// Hauteur de la capsule blanche.
  static const double _barHeight = 74;

  /// Diamètre du rond de l'onglet actif.
  static const double _bubbleSize = 56;

  /// Hauteur dont l'onglet actif se soulève au-dessus du bord de la barre.
  static const double _lift = 26;

  /// Espace entre le rond et le bord de l'encoche.
  static const double _notchGap = 7;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  );
  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  late int _from = widget.currentIndex;
  late int _to = widget.currentIndex;

  @override
  void initState() {
    super.initState();
    _controller.value = 1;
  }

  @override
  void didUpdateWidget(covariant PsyAvocatNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != _to) {
      _from = _to;
      _to = widget.currentIndex;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// Degré de sélection (0 → 1) de l'onglet [index] à l'instant courant.
  double _selection(int index) {
    final t = _curve.value;
    if (_from == _to) return index == _to ? 1 : 0;
    if (index == _to) return t;
    if (index == _from) return 1 - t;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        12,
        0,
        12,
        bottomInset > 0 ? bottomInset : 12,
      ),
      child: SizedBox(
        height: _barHeight + _lift + 4,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = constraints.maxWidth / widget.destinations.length;
            return AnimatedBuilder(
              animation: _curve,
              builder: (context, _) {
                final position = lerpDouble(
                  _from.toDouble(),
                  _to.toDouble(),
                  _curve.value,
                )!;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: _barHeight,
                      child: CustomPaint(
                        painter: NavBarPainter(
                          notchCenterX: itemWidth * (position + 0.5),
                          // Centre du rond actif, rapporté au bord supérieur de la barre.
                          notchCenterY: _bubbleSize / 2 - (_lift + 4),
                          notchRadius: _bubbleSize / 2 + _notchGap,
                          color: Colors.white,
                          shadowColor: primary.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Row(
                        children: [
                          for (var i = 0; i < widget.destinations.length; i++)
                            Expanded(
                              child: _NavItem(
                                destination: widget.destinations[i],
                                selection: _selection(i),
                                primary: primary,
                                barHeight: _barHeight,
                                bubbleSize: _bubbleSize,
                                lift: _lift,
                                onTap: () => widget.onDestinationSelected(i),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final NavDestination destination;

  /// 0 : onglet au repos ; 1 : onglet actif (soulevé dans son rond).
  final double selection;
  final Color primary;
  final double barHeight;
  final double bubbleSize;
  final double lift;
  final VoidCallback onTap;

  const _NavItem({
    required this.destination,
    required this.selection,
    required this.primary,
    required this.barHeight,
    required this.bubbleSize,
    required this.lift,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = selection;
    final iconColor = Color.lerp(context.palette.textSubtle, Colors.white, s)!;
    final labelColor = Color.lerp(context.palette.textSubtle, primary, s)!;
    // Repos : icône posée dans la barre. Actif : centre du rond au-dessus du bord.
    final restingTop = lift + 12;
    final activeTop = 0.0;
    final bubbleTop = lerpDouble(
      restingTop - (bubbleSize - 26) / 2,
      activeTop,
      s,
    )!;

    return Semantics(
      button: true,
      selected: s > 0.5,
      label: destination.tooltip ?? destination.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Positioned(
              top: bubbleTop,
              child: Container(
                width: bubbleSize,
                height: bubbleSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // Le rond se forme autour de l'icône au fur et à mesure.
                  color: primary.withValues(alpha: s),
                  boxShadow: s > 0
                      ? [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.35 * s),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Icon(
                    s > 0.5 ? destination.selectedIcon : destination.icon,
                    size: lerpDouble(25, 27, s),
                    color: iconColor,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 2,
              right: 2,
              bottom: 12,
              child: Text(
                destination.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.1,
                  color: labelColor,
                  fontWeight: s > 0.5 ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
