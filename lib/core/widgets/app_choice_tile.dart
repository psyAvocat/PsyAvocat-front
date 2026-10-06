import 'package:flutter/material.dart';
import '../theme/design_system.dart';

/// Carte de réponse cliquable, avec un [Radio] (choix unique)
/// ou une [Checkbox] (choix multiple) Material.
///
/// En choix unique, les tuiles doivent être placées sous un [RadioGroup]
/// qui porte la valeur sélectionnée :
/// ```dart
/// RadioGroup<String>(
///   groupValue: selectedId,
///   onChanged: (id) => select(id!),
///   child: Column(children: [
///     AppChoiceTile(value: 'r1', label: 'Oui', isSelected: selectedId == 'r1', onTap: ...),
///   ]),
/// )
/// ```
class AppChoiceTile extends StatelessWidget {
  final String value;
  final String label;
  final bool isSelected;
  final bool allowsMultiple;
  final VoidCallback onTap;

  const AppChoiceTile({
    super.key,
    required this.value,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.allowsMultiple = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: AppRadii.r16,
        boxShadow: isSelected
            ? AppShadows.selectedOption(scheme.primary)
            : null,
      ),
      child: Card(
        margin: EdgeInsets.zero,
        color: isSelected ? scheme.secondaryContainer : scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.r16,
          side: BorderSide(
            color: isSelected ? scheme.primary : scheme.outlineVariant,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s8,
              vertical: AppSpacing.s4,
            ),
            child: Row(
              children: [
                if (allowsMultiple)
                  Checkbox(value: isSelected, onChanged: (_) => onTap())
                else
                  Radio<String>(value: value),
                AppSpacing.hGap8,
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.s12,
                    ),
                    child: Text(
                      label,
                      style: AppTypography.texteMedium.copyWith(height: 1.3),
                    ),
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
