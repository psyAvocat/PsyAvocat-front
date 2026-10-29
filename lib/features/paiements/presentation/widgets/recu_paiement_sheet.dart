import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_alert.dart';
import '../../../../core/widgets/app_button.dart';

/// Données d'affichage d'un reçu officiel d'acompte PsyAvocat (20 %),
/// strictement adapté à l'univers (Avocat ou Psychologue).
class RecuPaiementData {
  final String referenceId;
  final String professionnelNom;
  final String? typeProfessionnel;
  final DateTime? dateRendezVous;
  final DateTime? datePaiement;
  final double montantAcompte;
  final double? montantTotal;
  final bool estAnnule;
  final bool simulation;
  final String? modeConsultation;

  const RecuPaiementData({
    required this.referenceId,
    required this.professionnelNom,
    required this.montantAcompte,
    this.typeProfessionnel,
    this.dateRendezVous,
    this.datePaiement,
    this.montantTotal,
    this.estAnnule = false,
    this.simulation = true,
    this.modeConsultation,
  });

  bool get estAvocat => typeProfessionnel?.toUpperCase() == 'AVOCAT';

  String get codeReference {
    final clean = referenceId.replaceAll('-', '').toUpperCase();
    final court = clean.length >= 8
        ? clean.substring(0, 8)
        : clean.padRight(8, '0');
    final prefixe = estAvocat ? 'AVO' : 'PSY';
    return 'REC-$prefixe-$court';
  }

  double get totalCalcule => montantTotal ?? (montantAcompte * 5);

  double get soldeRestant {
    final reste = totalCalcule - montantAcompte;
    return reste > 0 ? reste : 0;
  }
}

/// Affiche la feuille modale du reçu officiel d'acompte (20 %) PsyAvocat.
Future<void> showRecuPaiementSheet(
  BuildContext context,
  RecuPaiementData data,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _RecuPaiementSheet(data: data),
  );
}

class _RecuPaiementSheet extends StatelessWidget {
  final RecuPaiementData data;

  const _RecuPaiementSheet({required this.data});

  Future<void> _copierRecu(BuildContext context) async {
    final dateRdvStr = data.dateRendezVous != null
        ? '${Formatters.formatJourLong(data.dateRendezVous!)} à ${Formatters.formatHeure(data.dateRendezVous!)}'
        : '—';
    final labelPro = data.estAvocat ? tr('Avocat') : tr('Psychologue');
    final labelTotal = data.estAvocat
        ? tr('Honoraires totaux (100 %)')
        : tr('Tarif total de la séance (100 %)');
    final texte = [
      data.estAvocat
          ? '=== REÇU D\'ACOMPTE — CONSULTATION JURIDIQUE ==='
          : '=== REÇU D\'ACOMPTE — SÉANCE PSYCHOLOGIQUE ===',
      'Référence : ${data.codeReference}',
      'Statut : ${data.estAnnule ? "ANNULÉ" : "ACOMPTE RÉGLÉ (20 %)"}',
      '$labelPro : ${data.professionnelNom}',
      'Rendez-vous : $dateRdvStr',
      '$labelTotal : ${Formatters.formatFcfa(data.totalCalcule)}',
      'Acompte réglé (20 %) : ${Formatters.formatFcfa(data.montantAcompte)}',
      'Solde restant (80 %) : ${Formatters.formatFcfa(data.soldeRestant)}',
      '===============================================',
    ].join('\n');

    await Clipboard.setData(ClipboardData(text: texte));
    if (!context.mounted) return;
    AppNotification.showSuccess(
      context,
      tr('Récapitulatif du reçu copié dans le presse-papiers.'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final statutColor = data.estAnnule
        ? const Color(0xFFDC2626)
        : const Color(0xFF059669);

    final sousTitreUnivers = data.estAvocat
        ? tr('Consultation Juridique · Cabinet d’Avocat')
        : tr('Séance Clinique · Cabinet de Psychologie');
    final labelProfessionnel = data.estAvocat
        ? tr('Avocat')
        : tr('Psychologue');
    final labelMontantTotal = data.estAvocat
        ? tr('Honoraires totaux (100 %)')
        : tr('Tarif total de la séance (100 %)');
    final labelSoldeRestant = data.estAvocat
        ? tr('Solde restant à régler au cabinet (80 %)')
        : tr('Solde restant à régler lors de la séance (80 %)');

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.only(top: 48),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        decoration: BoxDecoration(
          color: context.palette.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Poignée supérieure
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.palette.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // En-tête officiel du reçu adapté à l'univers (Avocat vs Psychologue)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primary, primary.withValues(alpha: 0.85)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  data.estAvocat
                                      ? Icons.gavel_rounded
                                      : Icons.psychology_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data.estAvocat
                                          ? tr('Espace Avocat')
                                          : tr('Espace Psychologue'),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Text(
                                      sousTitreUnivers,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.85,
                                        ),
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            data.codeReference,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      Formatters.formatFcfa(data.montantAcompte),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tr('Acompte de confirmation (20 %)'),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Badge de statut
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statutColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statutColor.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        data.estAnnule
                            ? Icons.cancel_outlined
                            : Icons.check_circle_outline_rounded,
                        size: 16,
                        color: statutColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        data.estAnnule
                            ? tr('ACOMPTE ANNULÉ')
                            : (data.simulation
                                  ? tr('ACOMPTE VALIDÉ (SIMULATION V1)')
                                  : tr('ACOMPTE RÉGLÉ')),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: statutColor,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Détails du professionnel et du rendez-vous
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.palette.muted,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.palette.border),
                ),
                child: Column(
                  children: [
                    _LigneDetail(
                      label: labelProfessionnel,
                      valeur: data.professionnelNom.isNotEmpty
                          ? data.professionnelNom
                          : labelProfessionnel,
                      gras: true,
                    ),
                    if (data.dateRendezVous != null) ...[
                      const Divider(height: 18),
                      _LigneDetail(
                        label: tr('Date du rendez-vous'),
                        valeur:
                            '${Formatters.formatJourLong(data.dateRendezVous!)} · ${Formatters.formatHeure(data.dateRendezVous!)}',
                      ),
                    ],
                    if (data.modeConsultation != null &&
                        data.modeConsultation!.isNotEmpty) ...[
                      const Divider(height: 18),
                      _LigneDetail(
                        label: tr('Modalité'),
                        valeur: data.modeConsultation!,
                      ),
                    ],
                    if (data.datePaiement != null) ...[
                      const Divider(height: 18),
                      _LigneDetail(
                        label: tr('Date d\'émission'),
                        valeur: Formatters.formatLongDate(data.datePaiement),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Décomposition financière (100% / 20% / 80%)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.palette.muted,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.palette.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.estAvocat
                          ? tr('DÉTAIL DES HONORAIRES JURIDIQUES')
                          : tr('DÉTAIL TARIFAIRE DE LA SÉANCE'),
                      style: AppTypography.texteSemiBold.copyWith(
                        fontSize: 11,
                        letterSpacing: 0.6,
                        color: context.palette.textMuted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _LigneDetail(
                      label: labelMontantTotal,
                      valeur: Formatters.formatFcfa(data.totalCalcule),
                    ),
                    const SizedBox(height: 8),
                    _LigneDetail(
                      label: tr('Acompte de réservation (20 %)'),
                      valeur: Formatters.formatFcfa(data.montantAcompte),
                      gras: true,
                      couleurValeur: primary,
                    ),
                    const Divider(height: 20),
                    _LigneDetail(
                      label: labelSoldeRestant,
                      valeur: Formatters.formatFcfa(data.soldeRestant),
                      gras: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Actions : Copier / Fermer
              AppButton(
                text: tr('Copier le reçu officiel'),
                icon: Icons.copy_all_rounded,
                color: primary,
                onPressed: () => _copierRecu(context),
              ),
              const SizedBox(height: 10),
              AppButton(
                text: tr('Fermer'),
                isOutlined: true,
                color: primary,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LigneDetail extends StatelessWidget {
  final String label;
  final String valeur;
  final bool gras;
  final Color? couleurValeur;

  const _LigneDetail({
    required this.label,
    required this.valeur,
    this.gras = false,
    this.couleurValeur,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 5,
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: context.palette.textMuted),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 5,
          child: Text(
            valeur,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: gras ? FontWeight.w800 : FontWeight.w600,
              color: couleurValeur ?? context.palette.textStrong,
            ),
          ),
        ),
      ],
    );
  }
}
