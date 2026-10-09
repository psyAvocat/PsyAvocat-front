import 'package:flutter/material.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/contenu_model.dart';

/// Pastille de catégorie (spécialité choisie par l'auteur), si elle existe.
class PublicationCategoryChip extends StatelessWidget {
  final String label;

  const PublicationCategoryChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: AppRadii.pill,
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.badgeTexte.copyWith(color: scheme.primary),
      ),
    );
  }
}

/// Ligne d'informations : date de publication et temps de lecture.
/// Chaque information n'apparaît que si le backend l'a fournie.
class PublicationMetaRow extends StatelessWidget {
  final Publication publication;
  final bool showDate;

  const PublicationMetaRow({
    super.key,
    required this.publication,
    this.showDate = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    final style = AppTypography.miniTexte.copyWith(color: color);
    final minutes = publication.tempsLectureMinutes;

    return Wrap(
      spacing: AppSpacing.s12,
      runSpacing: AppSpacing.s4,
      children: [
        if (showDate && publication.datePublication != null)
          _MetaItem(
            icon: Icons.event_outlined,
            text: Formatters.formatLongDate(publication.datePublication),
            style: style,
            color: color,
          ),
        if (minutes != null)
          _MetaItem(
            icon: Icons.schedule_outlined,
            text: '$minutes min de lecture',
            style: style,
            color: color,
          ),
      ],
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final TextStyle style;
  final Color color;

  const _MetaItem({
    required this.icon,
    required this.text,
    required this.style,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        AppSpacing.hGap4,
        Flexible(child: Text(text, style: style)),
      ],
    );
  }
}
