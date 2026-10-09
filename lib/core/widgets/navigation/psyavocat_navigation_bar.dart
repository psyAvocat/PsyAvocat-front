import 'package:flutter/material.dart';
import 'nav_bar_painter.dart';
import 'nav_destination.dart';

export 'nav_destination.dart';

/// Barre de navigation inférieure personnalisée et animée pour PsyAvocat.
///
/// Reproduit fidèlement la maquette :
/// - Barre blanche horizontale flottante aux bords fortement arrondis.
/// - 4 destinations réparties de part et d'autre d'un bouton central surélevé.
/// - Bouton central circulaire surélevé avec ombre portée douce (Univers Avocat / Psychologue).
/// - Déplacement continu et fluide de l'indicateur/dôme blanc autour de l'élément actif.
/// - Icône active teintée avec la couleur primaire de l'univers, libellé actif mis en valeur.
/// - Synchronisation bidirectionnelle avec GoRouter via `currentIndex`.
///
/// Réutilisable : les onglets ([destinations]) sont fournis par l'appelant
/// (voir `features/navigation/presentation/navigation_destinations.dart`).
class PsyAvocatNavigationBar extends StatefulWidget {
  /// Les 5 onglets, dans l'ordre. Celui du milieu (index [centralIndex])
  /// est affiché comme bouton rond surélevé.
  final List<NavDestination> destinations;
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  /// Position du bouton central dans [destinations].
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
  late final AnimationController _controller;
  late Animation<double> _animation;

  late double _previousIndex;
  late double _targetIndex;
  late double _previousDomeProgress;
  late double _targetDomeProgress;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.currentIndex.toDouble();
    _targetIndex = widget.currentIndex.toDouble();
    _previousDomeProgress = widget.currentIndex == 2 ? 0.0 : 1.0;
    _targetDomeProgress = widget.currentIndex == 2 ? 0.0 : 1.0;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void didUpdateWidget(covariant PsyAvocatNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _previousIndex = _currentAnimatedIndex;
      _targetIndex = widget.currentIndex.toDouble();

      _previousDomeProgress = _currentDomeProgress;
      _targetDomeProgress = widget.currentIndex == 2 ? 0.0 : 1.0;

      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _currentAnimatedIndex {
    return _previousIndex + (_targetIndex - _previousIndex) * _animation.value;
  }

  double get _currentDomeProgress {
    return _previousDomeProgress +
        (_targetDomeProgress - _previousDomeProgress) * _animation.value;
  }

  @override
  Widget build(BuildContext context) {
    // Couleur de l'univers actif, fournie par le thème (jamais codée en dur).
    final primaryColor = Theme.of(context).colorScheme.primary;
    final destinations = widget.destinations;

    final bottomPadding = MediaQuery.of(context).padding.bottom;

    const double barHeight = 84.0;
    const double baselineY = 16.0;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final animatedIndex = _currentAnimatedIndex;
        final domeProgress = _currentDomeProgress;

        return Container(
          color: Colors.transparent,
          padding: EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            bottom: bottomPadding > 0 ? bottomPadding : 12.0,
            top: 2.0,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = constraints.maxWidth;
              final itemWidth = totalWidth / 5.0;
              final cx = totalWidth / 2.0;

              return SizedBox(
                width: totalWidth,
                height: barHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // 1. Fond blanc sculpté avec dôme animé et encoche centrale
                    Positioned.fill(
                      child: CustomPaint(
                        painter: NavBarPainter(
                          animatedIndex: animatedIndex,
                          domeProgress: domeProgress,
                          baselineY: baselineY,
                          bottomY: barHeight,
                          cornerRadius: 28.0,
                        ),
                      ),
                    ),

                    // 2. Bouton central surélevé
                    Positioned(
                      left: cx - 27.0,
                      top: baselineY - 14.0,
                      width: 54.0,
                      height: 54.0,
                      child: _CentralButton(
                        isSelected: widget.currentIndex == 2,
                        primaryColor: primaryColor,
                        icon: destinations[2].icon,
                        label: destinations[2].label,
                        onTap: () => widget.onDestinationSelected(2),
                      ),
                    ),

                    // 3. Les 4 destinations régulières (0, 1, 3, 4)
                    Positioned.fill(
                      child: Row(
                        children: List.generate(5, (index) {
                          if (index == 2) {
                            // Espace réservé au bouton central
                            return SizedBox(width: itemWidth);
                          }

                          final item = destinations[index];
                          final isSelected = widget.currentIndex == index;
                          // Calcul du décalage d'élévation lié au dôme actif
                          final distFromAnimated = (animatedIndex - index)
                              .abs();
                          final double lift = (distFromAnimated < 1.0)
                              ? (1.0 - distFromAnimated) * 5.0
                              : 0.0;

                          return Expanded(
                            child: _NavItem(
                              item: item,
                              isSelected: isSelected,
                              primaryColor: primaryColor,
                              lift: lift,
                              onTap: () => widget.onDestinationSelected(index),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// Bouton central surélevé représentant l'univers (Avocats / Psychologues).
class _CentralButton extends StatelessWidget {
  final bool isSelected;
  final Color primaryColor;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CentralButton({
    required this.isSelected,
    required this.primaryColor,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      selected: isSelected,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: isSelected ? 1.08 : 1.0,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutBack,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryColor,
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.38),
                  blurRadius: 12.0,
                  offset: const Offset(0, 5),
                ),
              ],
              border: isSelected
                  ? Border.all(color: Colors.white, width: 2.5)
                  : null,
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: Colors.white, size: 28.0),
          ),
        ),
      ),
    );
  }
}

/// Destination standard (icône + libellé).
class _NavItem extends StatelessWidget {
  final NavDestination item;
  final bool isSelected;
  final Color primaryColor;
  final double lift;
  final VoidCallback onTap;

  const _NavItem({
    required this.item,
    required this.isSelected,
    required this.primaryColor,
    required this.lift,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final inactiveColor = scheme.onSurfaceVariant;
    final activeTextColor = scheme.onSurface;

    return Semantics(
      label: item.label,
      selected: isSelected,
      button: true,
      child: InkResponse(
        onTap: onTap,
        radius: 36.0,
        containedInkWell: true,
        highlightShape: BoxShape.circle,
        splashColor: primaryColor.withValues(alpha: 0.12),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.only(top: 14.0),
          child: Transform.translate(
            offset: Offset(0, -lift),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icône avec transition de couleur et légère mise à l'échelle
                AnimatedScale(
                  scale: isSelected ? 1.06 : 1.0,
                  duration: const Duration(milliseconds: 220),
                  child: Icon(
                    isSelected ? item.selectedIcon : item.icon,
                    size: 24.0,
                    color: isSelected ? primaryColor : inactiveColor,
                  ),
                ),
                const SizedBox(height: 4.0),
                // Libellé textuel
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.0,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? activeTextColor : inactiveColor,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
