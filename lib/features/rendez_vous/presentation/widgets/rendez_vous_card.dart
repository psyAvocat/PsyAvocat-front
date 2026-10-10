import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../shared/enums/appointment_status.dart';
import '../../data/models/rendez_vous_model.dart';

class RendezVousCard extends StatelessWidget {
  final RendezVous item;
  final VoidCallback onTap;

  const RendezVousCard({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isConfirme = item.statut == AppointmentStatus.confirme;
    final isAnnule = item.statut == AppointmentStatus.annule;

    final statusColor = isConfirme
        ? const Color(0xFF16A34A)
        : isAnnule
        ? const Color(0xFFEF4444)
        : const Color(0xFFD97706);
    final statusBg = isConfirme
        ? const Color(0xFFDCFCE7)
        : isAnnule
        ? const Color(0xFFFEE2E2)
        : const Color(0xFFFEF3C7);

    final dayStr = DateFormat('d', 'fr_FR').format(item.dateHeure);
    final monthStr = DateFormat('MMM', 'fr_FR').format(item.dateHeure);
    final yearStr = DateFormat('yyyy', 'fr_FR').format(item.dateHeure);
    final timeStr =
        '${DateFormat('HH:mm', 'fr_FR').format(item.dateHeure)} - ${DateFormat('HH:mm', 'fr_FR').format(item.fin)}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge de date à gauche
            Container(
              width: 64,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isConfirme
                    ? const Color(0xFFEFF6FF)
                    : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Text(
                    dayStr,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isConfirme
                          ? const Color(0xFF1D4ED8)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                  Text(
                    monthStr,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isConfirme
                          ? const Color(0xFF1D4ED8)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                  Text(
                    yearStr,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 14),

            // Détails au centre
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    timeStr,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          item.professionnelDisplayName,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.typeProfessionnel,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.professionnelSpecialite ?? '',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: Color(0xFF9CA3AF),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.mode ?? 'Non spécifié',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      item.statut.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }
}
