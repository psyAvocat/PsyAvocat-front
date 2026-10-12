import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../shared/enums/appointment_status.dart';
import '../../data/models/rendez_vous_model.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/l10n/app_strings.dart';

class RendezVousDetailsSheet extends StatelessWidget {
  final RendezVous item;
  final VoidCallback onCancel;

  const RendezVousDetailsSheet({
    super.key,
    required this.item,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final dayStr = DateFormat('d').format(item.dateHeure);
    final monthStr = DateFormat('MMM').format(item.dateHeure);
    final yearStr = DateFormat('yyyy').format(item.dateHeure);
    final timeStr =
        '${DateFormat('HH:mm').format(item.dateHeure)} - ${DateFormat('HH:mm').format(item.fin)}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.palette.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.professionnelDisplayName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: context.palette.textStrong,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: item.statut == AppointmentStatus.confirme
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item.statut.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: item.statut == AppointmentStatus.confirme
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${item.typeLabel} • ${item.professionnelSpecialite ?? ''}',
            style: TextStyle(fontSize: 14, color: context.palette.text),
          ),
          const Divider(height: 24),
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 16,
                color: context.palette.textMuted,
              ),
              const SizedBox(width: 8),
              Text(
                tr('{date} à {heure}', {
                  'date': '$dayStr $monthStr $yearStr',
                  'heure': timeStr,
                }),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 16,
                color: context.palette.textMuted,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(item.modeLabel ?? tr('Non spécifié'))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.payments_outlined,
                size: 16,
                color: context.palette.textMuted,
              ),
              const SizedBox(width: 8),
              Text(
                tr(
                  'Honoraires : {total} FCFA (Acompte réglé : {acompte} FCFA)',
                  {
                    'total': item.montantTotal ?? 0,
                    'acompte': item.montantAcompte ?? 0,
                  },
                ),
              ),
            ],
          ),
          if (item.canBeChangedAt(DateTime.now())) ...[
            const SizedBox(height: 24),
            AppButton.outline(
              text: tr('Annuler ce rendez-vous'),
              color: AppColors.danger,
              onPressed: onCancel,
            ),
          ],
        ],
      ),
    );
  }
}
