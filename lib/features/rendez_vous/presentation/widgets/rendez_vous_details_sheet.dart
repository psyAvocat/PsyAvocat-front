import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../shared/enums/appointment_status.dart';
import '../../data/models/rendez_vous_model.dart';

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
    final dayStr = DateFormat('d', 'fr_FR').format(item.dateHeure);
    final monthStr = DateFormat('MMM', 'fr_FR').format(item.dateHeure);
    final yearStr = DateFormat('yyyy', 'fr_FR').format(item.dateHeure);
    final timeStr =
        '${DateFormat('HH:mm', 'fr_FR').format(item.dateHeure)} - ${DateFormat('HH:mm', 'fr_FR').format(item.fin)}';

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
                color: const Color(0xFFE5E7EB),
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
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
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
            '${item.typeProfessionnel} • ${item.professionnelSpecialite ?? ''}',
            style: const TextStyle(fontSize: 14, color: Color(0xFF4B5563)),
          ),
          const Divider(height: 24),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                size: 16,
                color: Color(0xFF6B7280),
              ),
              const SizedBox(width: 8),
              Text('$dayStr $monthStr $yearStr à $timeStr'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: Color(0xFF6B7280),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(item.mode ?? 'Non spécifié')),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.payments_outlined,
                size: 16,
                color: Color(0xFF6B7280),
              ),
              const SizedBox(width: 8),
              Text(
                'Honoraires : ${item.montantTotal ?? 0} FCFA (Acompte réglé : ${item.montantAcompte ?? 0} FCFA)',
              ),
            ],
          ),
          if (item.canBeChangedAt(DateTime.now())) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: onCancel,
                icon: const Icon(
                  Icons.cancel_outlined,
                  color: Color(0xFFEF4444),
                  size: 18,
                ),
                label: const Text(
                  'Annuler ce rendez-vous',
                  style: TextStyle(
                    color: Color(0xFFEF4444),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
