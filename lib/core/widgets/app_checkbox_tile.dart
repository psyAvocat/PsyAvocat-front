import 'package:flutter/material.dart';
import '../theme/design_system.dart';

/// [Checkbox] Material suivie d'un texte (ex. acceptation des CGU).
///
/// [label] est un widget pour pouvoir y mettre du texte enrichi (mots en couleur).
/// Toute la ligne est cliquable.
///
/// Exemple :
/// ```dart
/// AppCheckboxTile(
///   value: _accepted,
///   onChanged: (value) => setState(() => _accepted = value),
///   label: const Text("J'accepte les conditions"),
/// )
/// ```
class AppCheckboxTile extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget label;

  const AppCheckboxTile({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: AppRadii.r8,
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: (newValue) => onChanged(newValue ?? false),
          ),
          AppSpacing.hGap4,
          Expanded(child: label),
        ],
      ),
    );
  }
}
