import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/user_message.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/theme/universe_provider.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../shared/enums/appointment_status.dart';
import '../../../professionnels/presentation/controllers/professionnels_controller.dart';
import '../../../rendez_vous/data/models/rendez_vous_model.dart';
import '../../../rendez_vous/data/models/reservation_contexte.dart';
import '../../../rendez_vous/presentation/controllers/rendez_vous_controller.dart';
import '../../data/models/dossier_model.dart';
import '../controllers/dossiers_controller.dart';
import '../widgets/dossier_ui.dart';

/// « Dossier pris en charge » : l'avocat qui a accepté le dossier, sa réponse,
/// ses honoraires et les rendez-vous déjà pris pour ce dossier, avec un accès
/// direct à ses disponibilités (« Prendre rendez-vous »).
///
/// Ouvert depuis la liste des dossiers, la consultation du dossier, la
/// notification « Dossier accepté » ou la fiche de l'avocat.
class DossierPriseEnChargeScreen extends ConsumerWidget {
  final String dossierId;

  /// Vrai si l'écran est ouvert depuis la consultation du dossier : « Voir le
  /// dossier complet » y revient au lieu d'empiler une nouvelle page.
  final bool depuisDossier;

  const DossierPriseEnChargeScreen({
    super.key,
    required this.dossierId,
    this.depuisDossier = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final universe = ref.watch(currentUniverseProvider);
    final dossierAsync = ref.watch(dossierDetailProvider(dossierId));

    return Scaffold(
      backgroundColor: context.palette.page,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const AppBackButton(),
        title: Text(tr('Dossier pris en charge')),
      ),
      body: dossierAsync.when(
        loading: () => AppLoadingView(universe: universe),
        error: (e, _) => AppErrorStateView(
          title: tr('Dossier indisponible'),
          message: userMessageFor(e),
          onRetry: () => ref.invalidate(dossierDetailProvider(dossierId)),
        ),
        data: (dossier) {
          final soumission = dossier.soumissionRetenue;
          if (soumission == null) {
            return AppEmptyStateView(
              icon: Icons.hourglass_top_rounded,
              title: tr('Pas encore de prise en charge'),
              message: tr(
                'Aucun avocat n’a encore accepté ce dossier. Vous serez prévenu dès qu’un avocat l’accepte.',
              ),
              actionText: tr('Voir le dossier'),
              onAction: () => _voirDossier(context),
            );
          }
          return _Contenu(
            dossier: dossier,
            soumission: soumission,
            onVoirDossier: () => _voirDossier(context),
          );
        },
      ),
    );
  }

  void _voirDossier(BuildContext context) {
    if (depuisDossier && context.canPop()) {
      context.pop();
    } else {
      context.push(AppRoutes.dossier(dossierId));
    }
  }
}

class _Contenu extends ConsumerWidget {
  final DossierModel dossier;
  final SoumissionModel soumission;
  final VoidCallback onVoirDossier;

  const _Contenu({
    required this.dossier,
    required this.soumission,
    required this.onVoirDossier,
  });

  void _prendreRendezVous(BuildContext context) {
    context.push(
      AppRoutes.choixCreneau(soumission.avocatId),
      extra: ReservationContexte.avocat(
        professionnelId: soumission.avocatId,
        soumissionId: soumission.id,
        dossierTitre: dossier.titre,
        montantDossier: soumission.tarifPropose!,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primary = context.colors.primary;
    final honoraires = soumission.tarifPropose;
    final maintenant = DateTime.now();
    final rendezVous =
        (ref.watch(rendezVousControllerProvider).value ?? const <RendezVous>[])
            .where(
              (r) =>
                  r.dossierId == dossier.id &&
                  r.phaseAt(maintenant) == AppointmentPhase.aVenir,
            )
            .toList()
          ..sort((a, b) => a.dateHeure.compareTo(b.dateHeure));

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await ref.read(dossiersListProvider.notifier).refresh();
              await ref.read(rendezVousControllerProvider.notifier).reload();
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
              children: [
                _Bandeau(dossier: dossier, soumission: soumission),
                AppSpacing.vGap16,
                _Avocat(soumission: soumission),
                if (soumission.reponse?.trim().isNotEmpty ?? false) ...[
                  AppSpacing.vGap12,
                  _Carte(
                    titre: tr('Message de l’avocat'),
                    icone: Icons.format_quote_rounded,
                    child: Text(
                      soumission.reponse!.trim(),
                      style: AppTypography.texte.copyWith(
                        fontSize: 14,
                        height: 1.5,
                        fontStyle: FontStyle.italic,
                        color: context.palette.textStrong,
                      ),
                    ),
                  ),
                ],
                if (honoraires != null) ...[
                  AppSpacing.vGap12,
                  _Carte(
                    titre: tr('Honoraires proposés'),
                    icone: Icons.receipt_long_outlined,
                    child: _Honoraires(montant: honoraires),
                  ),
                ],
                AppSpacing.vGap12,
                _Carte(
                  titre: tr('Rendez-vous pour ce dossier'),
                  icone: Icons.event_available_outlined,
                  child: rendezVous.isEmpty
                      ? Text(
                          tr(
                            'Aucun rendez-vous pour le moment. Choisissez un créneau dans les disponibilités de l’avocat.',
                          ),
                          style: DossierText.secondaire(
                            context,
                          ).copyWith(fontSize: 13, height: 1.4),
                        )
                      : Column(
                          children: [
                            for (final r in rendezVous) _LigneRendezVous(r),
                          ],
                        ),
                ),
                AppSpacing.vGap12,
                _Carte(
                  titre: tr('Et maintenant ?'),
                  icone: Icons.route_outlined,
                  child: Column(
                    children: [
                      _Etape(
                        numero: 1,
                        texte: tr(
                          'Choisissez un créneau libre dans l’agenda de l’avocat.',
                        ),
                      ),
                      _Etape(
                        numero: 2,
                        texte: tr(
                          'Réglez l’acompte de 20 % (paiement simulé) pour confirmer.',
                        ),
                      ),
                      _Etape(
                        numero: 3,
                        texte: tr(
                          'Rencontrez votre avocat au cabinet ou en visioconférence.',
                        ),
                        dernier: true,
                      ),
                    ],
                  ),
                ),
                AppSpacing.vGap12,
                Center(
                  child: TextButton.icon(
                    onPressed: onVoirDossier,
                    icon: const Icon(Icons.folder_open_outlined, size: 18),
                    label: Text(tr('Voir le dossier complet')),
                    style: TextButton.styleFrom(foregroundColor: primary),
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          decoration: BoxDecoration(
            color: context.palette.card,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: AppButton(
              text: rendezVous.isEmpty
                  ? tr('Prendre rendez-vous')
                  : tr('Prendre un autre rendez-vous'),
              icon: Icons.calendar_month_rounded,
              color: primary,
              onPressed: honoraires == null || soumission.avocatId.isEmpty
                  ? null
                  : () => _prendreRendezVous(context),
            ),
          ),
        ),
      ],
    );
  }
}

/// En-tête : confirmation visuelle de la prise en charge.
class _Bandeau extends StatelessWidget {
  final DossierModel dossier;
  final SoumissionModel soumission;

  const _Bandeau({required this.dossier, required this.soumission});

  @override
  Widget build(BuildContext context) {
    final primary = context.colors.primary;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary, Color.lerp(primary, Colors.black, 0.25)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          AppSpacing.hGap12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('Votre dossier est entre de bonnes mains'),
                  style: AppTypography.texteSemiBold.copyWith(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                AppSpacing.vGap4,
                Text(
                  tr('{avocat} a accepté votre dossier « {titre} ».', {
                    'avocat': soumission.displayName,
                    'titre': dossier.titre,
                  }),
                  style: AppTypography.texte.copyWith(
                    fontSize: 13,
                    height: 1.4,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
                if (soumission.dateReponse != null) ...[
                  AppSpacing.vGap8,
                  Text(
                    tr('Réponse du {date}', {
                      'date': Formatters.formatDateHeure(
                        soumission.dateReponse!,
                      ),
                    }),
                    style: AppTypography.texte.copyWith(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Avocat : photo, spécialités, ville (fiche publique), lien vers son profil.
class _Avocat extends ConsumerWidget {
  final SoumissionModel soumission;
  const _Avocat({required this.soumission});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pro = soumission.avocatId.isEmpty
        ? null
        : ref.watch(professionnelDetailProvider(soumission.avocatId)).value;
    final summary = pro?.summary;
    final details = [
      if (summary != null && summary.specialites.isNotEmpty)
        summary.specialites.take(2).join(' · '),
      if (summary?.ville?.isNotEmpty ?? false) summary!.ville!,
    ];

    return DossierCardContainer(
      child: Row(
        children: [
          AppAvatar(
            name: '${soumission.avocatPrenom} ${soumission.avocatNom}',
            photoUrl: summary?.photoUrl,
            size: 56,
          ),
          AppSpacing.hGap12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  soumission.displayName,
                  style: AppTypography.texteSemiBold.copyWith(
                    fontSize: 16,
                    color: context.colors.primary,
                  ),
                ),
                AppSpacing.vGap4,
                Text(
                  details.isEmpty ? tr('Avocat') : details.join(' — '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: DossierText.secondaire(context),
                ),
                if (pro?.adresse?.isNotEmpty ?? false) ...[
                  AppSpacing.vGap4,
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: context.palette.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          pro!.adresse!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: DossierText.petit(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (soumission.avocatId.isNotEmpty)
            TextButton(
              onPressed: () =>
                  context.push(AppRoutes.professionnel(soumission.avocatId)),
              child: Text(tr('Profil')),
            ),
        ],
      ),
    );
  }
}

class _Honoraires extends StatelessWidget {
  final double montant;
  const _Honoraires({required this.montant});

  @override
  Widget build(BuildContext context) {
    final acompte =
        (montant * ReservationRecap.tauxAcompte * 100).roundToDouble() / 100;
    return Column(
      children: [
        _Montant(
          libelle: tr('Honoraires totaux'),
          valeur: Formatters.formatFcfa(montant),
          fort: true,
        ),
        _Montant(
          libelle: tr('Acompte à la réservation (20 %)'),
          valeur: Formatters.formatFcfa(acompte),
        ),
        _Montant(
          libelle: tr('Reste à régler à l’avocat'),
          valeur: Formatters.formatFcfa(montant - acompte),
        ),
      ],
    );
  }
}

class _Montant extends StatelessWidget {
  final String libelle;
  final String valeur;
  final bool fort;

  const _Montant({
    required this.libelle,
    required this.valeur,
    this.fort = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
          Text(
            valeur,
            style: AppTypography.texteSemiBold.copyWith(
              fontSize: fort ? 16 : 13,
              color: fort ? context.colors.primary : context.palette.textStrong,
            ),
          ),
        ],
      ),
    );
  }
}

class _LigneRendezVous extends StatelessWidget {
  final RendezVous rdv;
  const _LigneRendezVous(this.rdv);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.palette.chip,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              rdv.mode == 'VISIO'
                  ? Icons.videocam_outlined
                  : Icons.apartment_rounded,
              size: 20,
              color: context.colors.primary,
            ),
          ),
          AppSpacing.hGap12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Formatters.formatJourLong(rdv.dateHeure),
                  style: AppTypography.texteSemiBold.copyWith(
                    fontSize: 13,
                    color: context.palette.textStrong,
                  ),
                ),
                Text(
                  [
                    '${Formatters.formatHeure(rdv.dateHeure)} – ${Formatters.formatHeure(rdv.fin)}',
                    if (rdv.modeLabel != null) rdv.modeLabel!,
                  ].join(' · '),
                  style: DossierText.secondaire(context),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: tr('Mes rendez-vous'),
            onPressed: () => context.go(AppRoutes.rendezVous),
            icon: Icon(
              Icons.chevron_right_rounded,
              color: context.palette.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _Etape extends StatelessWidget {
  final int numero;
  final String texte;
  final bool dernier;

  const _Etape({
    required this.numero,
    required this.texte,
    this.dernier = false,
  });

  @override
  Widget build(BuildContext context) {
    final primary = context.colors.primary;
    return Padding(
      padding: EdgeInsets.only(bottom: dernier ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$numero',
              style: AppTypography.texteSemiBold.copyWith(
                fontSize: 12,
                color: primary,
              ),
            ),
          ),
          AppSpacing.hGap12,
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                texte,
                style: AppTypography.texte.copyWith(
                  fontSize: 13,
                  height: 1.4,
                  color: context.palette.text,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Carte extends StatelessWidget {
  final String titre;
  final IconData icone;
  final Widget child;

  const _Carte({required this.titre, required this.icone, required this.child});

  @override
  Widget build(BuildContext context) {
    return DossierCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, size: 18, color: context.colors.primary),
              const SizedBox(width: 8),
              Text(titre, style: DossierText.section(context)),
            ],
          ),
          AppSpacing.vGap12,
          child,
        ],
      ),
    );
  }
}
