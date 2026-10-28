import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../shared/enums/appointment_status.dart';
import '../../data/models/rendez_vous_model.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/l10n/app_strings.dart';

class RendezVousCard extends StatelessWidget {
  final RendezVous item;
  final VoidCallback onTap;

  const RendezVousCard({super.key, required this.item, required this.onTap});

  Future<void> _openVisio(String rawUrl) async {
    final rawBase = rawUrl.contains('meet.google.com') ? 'https://meet.ffmuc.net/PsyAvocat-Consultation-' : rawUrl.trim().replaceAll('https://meet.jit.si/', 'https://meet.ffmuc.net/');
    final target = '$rawBase#config.startWithAudioMuted=false&config.startWithVideoMuted=false&config.prejoinPageEnabled=false&config.defaultLanguage=%22fr%22';
    final uri = Uri.tryParse(target);
    if (uri == null) return;
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }

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

    final dayStr = DateFormat('d').format(item.dateHeure);
    final monthStr = DateFormat('MMM').format(item.dateHeure);
    final yearStr = DateFormat('yyyy').format(item.dateHeure);
    final timeStr =
        '${DateFormat('HH:mm').format(item.dateHeure)} - ${DateFormat('HH:mm').format(item.fin)}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.palette.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.palette.border, width: 1.2),
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
                    : context.palette.muted,
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
                          : context.palette.textMuted,
                    ),
                  ),
                  Text(
                    monthStr,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isConfirme
                          ? const Color(0xFF1D4ED8)
                          : context.palette.textMuted,
                    ),
                  ),
                  Text(
                    yearStr,
                    style: TextStyle(
                      fontSize: 10,
                      color: context.palette.textMuted,
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
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: context.palette.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          item.professionnelDisplayName,
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: context.palette.textStrong,
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
                          color: context.palette.muted,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.typeLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: context.palette.text,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.professionnelSpecialite ?? '',
                    style: TextStyle(fontSize: 13, color: context.palette.text),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: context.palette.textSubtle,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.modeLabel ?? tr('Non spécifié'),
                          style: TextStyle(
                            fontSize: 12,
                            color: context.palette.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
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
                      if (item.lienVisio != null &&
                          item.lienVisio!.isNotEmpty &&
                          !isAnnule)
                        InkWell(
                          onTap: () => _openVisio(item.lienVisio!),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F9D58),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.videocam_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  tr('Rejoindre la visio'),
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: context.palette.textSubtle,
            ),
          ],
        ),
      ),
    );
  }
}
