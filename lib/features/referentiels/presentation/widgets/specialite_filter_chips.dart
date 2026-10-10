import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/design_system.dart';
import '../../data/models/specialite_option.dart';
import '../controllers/specialites_provider.dart';

/// Rangée de filtres « Tous » + spécialités de l'univers actif (référentiel
/// administré dans Angular). Rien n'est affiché si aucune spécialité n'existe.
///
/// Exemple : `SpecialiteFilterChips(selectedId: _id, onSelected: (s) => ...)`.
/// [onSelected] reçoit `null` pour « Tous ».
class SpecialiteFilterChips extends ConsumerWidget {
  final String? selectedId;
  final ValueChanged<SpecialiteOption?> onSelected;

  const SpecialiteFilterChips({
    super.key,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final specialites =
        ref.watch(specialitesOfUniverseProvider).value ?? const [];
    if (specialites.isEmpty) return const SizedBox.shrink();

    final options = <SpecialiteOption?>[null, ...specialites];
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
        itemCount: options.length,
        separatorBuilder: (_, _) => AppSpacing.hGap8,
        itemBuilder: (context, index) {
          final option = options[index];
          return ChoiceChip(
            label: Text(option?.nom ?? 'Tous'),
            selected: option?.id == selectedId,
            onSelected: (_) => onSelected(option),
          );
        },
      ),
    );
  }
}
