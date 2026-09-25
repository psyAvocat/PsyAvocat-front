import 'package:flutter/material.dart';
import '../theme/design_system.dart';

/// AppBar standardisée pour PsyAvocat.
class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final bool isTransparent;
  final bool useGradient;
  final AppUniverse? universe;
  final double elevation;
  final PreferredSizeWidget? bottom;

  const AppAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.showBackButton = true,
    this.onBackPressed,
    this.isTransparent = false,
    this.useGradient = false,
    this.universe,
    this.elevation = 0,
    this.bottom,
  });

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0.0),
      );

  @override
  Widget build(BuildContext context) {
    final universeColors = universe != null
        ? AppUniverseColors.fromUniverse(universe!)
        : AppTheme.universeOf(context);

    final canPop = ModalRoute.of(context)?.canPop ?? false;
    final shouldShowBack = showBackButton && (canPop || onBackPressed != null);

    final Color foregroundColor =
        useGradient ? AppColors.textOnColor : AppColors.textPrimary;

    Widget? effectiveLeading = leading;
    if (effectiveLeading == null && shouldShowBack) {
      effectiveLeading = IconButton(
        icon: Icon(
          AppIcons.back,
          size: 20,
          color: foregroundColor,
        ),
        tooltip: 'Retour',
        onPressed: onBackPressed ?? () => Navigator.of(context).maybePop(),
      );
    }

    Widget? effectiveTitle = titleWidget;
    if (effectiveTitle == null && title != null) {
      effectiveTitle = Text(
        title!,
        style: AppTypography.titreMoyen.copyWith(
          fontSize: 18,
          color: foregroundColor,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isTransparent
            ? Colors.transparent
            : (useGradient ? null : AppColors.neutralSurface),
        gradient: useGradient ? universeColors.gradient : null,
        border: (isTransparent || useGradient)
            ? null
            : const Border(
                bottom: BorderSide(color: AppColors.border, width: 1),
              ),
      ),
      child: AppBar(
        title: effectiveTitle,
        centerTitle: true,
        leading: effectiveLeading,
        actions: actions,
        elevation: elevation,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: foregroundColor,
        bottom: bottom,
      ),
    );
  }
}

/// Sélecteur d'univers (Psychologue vs Avocat) avec transition visuelle élégante.
class AppUniverseSwitch extends StatelessWidget {
  final AppUniverse currentUniverse;
  final ValueChanged<AppUniverse> onUniverseChanged;

  const AppUniverseSwitch({
    super.key,
    required this.currentUniverse,
    required this.onUniverseChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.neutralSurfaceSecondary,
        borderRadius: AppRadii.r16,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildUniverseTab(
              context: context,
              universe: AppUniverse.lawyer,
              title: 'Avocat',
              icon: AppIcons.lawyer,
              activeColor: AppColors.lawyer,
              isSelected: currentUniverse == AppUniverse.lawyer,
            ),
          ),
          AppSpacing.hGap8,
          Expanded(
            child: _buildUniverseTab(
              context: context,
              universe: AppUniverse.psychologist,
              title: 'Psychologue',
              icon: AppIcons.psychologist,
              activeColor: AppColors.psychologist,
              isSelected: currentUniverse == AppUniverse.psychologist,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUniverseTab({
    required BuildContext context,
    required AppUniverse universe,
    required String title,
    required IconData icon,
    required Color activeColor,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => onUniverseChanged(universe),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: AppRadii.r12,
          boxShadow: isSelected ? AppShadows.buttonUniverse(activeColor) : AppShadows.none,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: AppIcons.sizeSm,
              color: isSelected ? AppColors.textOnColor : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: AppTypography.texteSemiBold.copyWith(
                fontSize: 14,
                color: isSelected ? AppColors.textOnColor : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
