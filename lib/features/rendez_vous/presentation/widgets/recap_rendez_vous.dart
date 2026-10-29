import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_avatar.dart';

/// Récapitulatif d'un rendez-vous : professionnel, date et heure côte à côte,
/// lieu, dossier. Utilisé avant la confirmation, après, et dans le détail.
class RecapRendezVousCard extends StatelessWidget {
  final String professionnelNom;
  final String? photoUrl;

  /// « Avocat · Droit pénal », « Psychologue »…
  final String? sousTitre;
  final DateTime debut;
  final DateTime fin;

  /// Code serveur : VISIO, CABINET…
  final String? mode;
  final String? adresse;
  final String? dossierTitre;

  /// Pastille facultative à droite du nom (statut du rendez-vous).
  final Widget? statut;

  const RecapRendezVousCard({
    super.key,
    required this.professionnelNom,
    required this.debut,
    required this.fin,
    this.photoUrl,
    this.sousTitre,
    this.mode,
    this.adresse,
    this.dossierTitre,
    this.statut,
  });

  @override
  Widget build(BuildContext context) {
    final visio = mode?.toUpperCase() == 'VISIO';
    final lieu = visio
        ? tr('En visioconférence')
        : [
            tr('Au cabinet'),
            if (adresse?.trim().isNotEmpty ?? false) adresse!.trim(),
          ].join(' — ');

    return _Carte(
      children: [
        Row(
          children: [
            AppAvatar(name: professionnelNom, photoUrl: photoUrl, size: 48),
            AppSpacing.hGap12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    professionnelNom,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.texteSemiBold.copyWith(
                      fontSize: 16,
                      color: context.palette.textStrong,
                    ),
                  ),
                  if (sousTitre?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 2),
                    Text(
                      sousTitre!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.texte.copyWith(
                        fontSize: 13,
                        color: context.palette.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            ?statut,
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          decoration: BoxDecoration(
            color: context.palette.muted,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _Info(
                    icone: Icons.calendar_today_rounded,
                    libelle: tr('Date'),
                    valeur: Formatters.formatJourLong(debut),
                  ),
                ),
                VerticalDivider(
                  width: 24,
                  thickness: 1,
                  color: context.palette.border,
                ),
                Expanded(
                  child: _Info(
                    icone: Icons.schedule_rounded,
                    libelle: tr('Heure'),
                    valeur:
                        '${Formatters.formatHeure(debut)} – ${Formatters.formatHeure(fin)}',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        _Ligne(
          icone: visio ? Icons.videocam_outlined : Icons.location_on_outlined,
          libelle: visio ? tr('Mode') : tr('Lieu'),
          valeur: lieu,
        ),
        if (dossierTitre?.trim().isNotEmpty ?? false) ...[
          const SizedBox(height: 12),
          _Ligne(
            icone: Icons.folder_outlined,
            libelle: tr('Dossier'),
            valeur: dossierTitre!.trim(),
          ),
        ],
      ],
    );
  }
}

/// Montants : total, acompte de 20 % et reste à régler au professionnel.
class RecapMontantsCard extends StatelessWidget {
  final double total;
  final double? acompte;
  final String libelleTotal;
  final String libelleAcompte;

  /// Mention facultative sous le titre (ex. « Acompte réglé »).
  final String? etat;

  const RecapMontantsCard({
    super.key,
    required this.total,
    required this.libelleTotal,
    required this.libelleAcompte,
    this.acompte,
    this.etat,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return _Carte(
      children: [
        Row(
          children: [
            Icon(Icons.receipt_long_outlined, size: 18, color: primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                tr('Paiement'),
                style: AppTypography.texteSemiBold.copyWith(
                  fontSize: 15,
                  color: context.palette.textStrong,
                ),
              ),
            ),
            if (etat != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  etat!,
                  style: AppTypography.texteSemiBold.copyWith(
                    fontSize: 11,
                    color: primary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _Montant(libelle: libelleTotal, valeur: Formatters.formatFcfa(total)),
        if (acompte != null) ...[
          _Montant(
            libelle: libelleAcompte,
            valeur: Formatters.formatFcfa(acompte!),
            couleur: primary,
          ),
          Divider(height: 20, color: context.palette.border),
          _Montant(
            libelle: tr('Reste à régler au professionnel'),
            valeur: Formatters.formatFcfa(total - acompte!),
            fort: true,
          ),
        ],
      ],
    );
  }
}

class _Carte extends StatelessWidget {
  final List<Widget> children;
  const _Carte({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

/// Information compacte : icône, petit libellé, valeur.
class _Info extends StatelessWidget {
  final IconData icone;
  final String libelle;
  final String valeur;

  const _Info({
    required this.icone,
    required this.libelle,
    required this.valeur,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icone, size: 14, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              libelle,
              style: AppTypography.texte.copyWith(
                fontSize: 11,
                color: context.palette.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          valeur,
          style: AppTypography.texteSemiBold.copyWith(
            fontSize: 14,
            color: context.palette.textStrong,
          ),
        ),
      ],
    );
  }
}

/// Ligne pleine largeur : icône dans une pastille, libellé et valeur.
class _Ligne extends StatelessWidget {
  final IconData icone;
  final String libelle;
  final String valeur;

  const _Ligne({
    required this.icone,
    required this.libelle,
    required this.valeur,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icone, size: 18, color: primary),
        ),
        AppSpacing.hGap12,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                libelle,
                style: AppTypography.texte.copyWith(
                  fontSize: 11,
                  color: context.palette.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                valeur,
                style: AppTypography.texteSemiBold.copyWith(
                  fontSize: 14,
                  height: 1.35,
                  color: context.palette.textStrong,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Montant extends StatelessWidget {
  final String libelle;
  final String valeur;
  final Color? couleur;
  final bool fort;

  const _Montant({
    required this.libelle,
    required this.valeur,
    this.couleur,
    this.fort = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              libelle,
              style: AppTypography.texte.copyWith(
                fontSize: 13,
                color: context.palette.text,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            valeur,
            style: AppTypography.texteSemiBold.copyWith(
              fontSize: fort ? 16 : 14,
              color: couleur ?? context.palette.textStrong,
            ),
          ),
        ],
      ),
    );
  }
}
