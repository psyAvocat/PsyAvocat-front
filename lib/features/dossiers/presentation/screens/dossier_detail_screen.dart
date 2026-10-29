import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/errors/user_message.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/theme/universe_provider.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_alert.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../profile/presentation/widgets/current_user_avatar.dart';
import '../../../rendez_vous/data/models/reservation_contexte.dart';
import '../../data/models/dossier_model.dart';
import '../../data/repositories/dossier_repository.dart';
import '../controllers/dossiers_controller.dart';
import '../widgets/dossier_ui.dart';
import '../../../../core/l10n/app_strings.dart';

/// « Mon dossier » — maquette Figma « Consultation du dossier » : résumé,
/// avocats destinataires et leurs réponses, pièces jointes, suivi chronologique.
///
/// Dès qu'un avocat accepte (honoraires proposés), le dossier lui est confié
/// (les autres soumissions deviennent caduques) : un encart mène à l'écran de
/// prise en charge et à la prise de rendez-vous avec cet avocat.
class DossierDetailScreen extends ConsumerWidget {
  final String dossierId;

  const DossierDetailScreen({super.key, required this.dossierId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final universe = ref.watch(currentUniverseProvider);
    final dossierAsync = ref.watch(dossierDetailProvider(dossierId));

    return Scaffold(
      backgroundColor: context.palette.card,
      appBar: AppPageHeader(
        title: tr('Mon dossier'),
        trailing: CurrentUserAvatar(),
      ),
      body: dossierAsync.when(
        loading: () => AppLoadingView(universe: universe),
        error: (e, _) => AppErrorStateView(
          title: tr('Dossier indisponible'),
          message: userMessageFor(e),
          onRetry: () => ref.invalidate(dossierDetailProvider(dossierId)),
        ),
        data: (dossier) => RefreshIndicator(
          onRefresh: () => ref.read(dossiersListProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
            children: [
              _Resume(dossier: dossier),
              if (dossier.soumissionRetenue != null) ...[
                AppSpacing.vGap12,
                _EncartPriseEnCharge(
                  dossier: dossier,
                  soumission: dossier.soumissionRetenue!,
                ),
              ],
              AppSpacing.vGap16,
              _SectionTitre(
                titre: tr('Avocats destinataires'),
                info: dossier.estPrisEnCharge ? null : tr('Choisir 1 avocat'),
              ),
              for (final soumission in dossier.soumissions) ...[
                _AvocatCard(dossier: dossier, soumission: soumission),
                AppSpacing.vGap8,
              ],
              if (dossier.soumissions.isEmpty)
                Text(
                  tr('Aucun avocat sollicité pour le moment.'),
                  style: DossierText.secondaire(context),
                ),
              if (dossier.piecesJointes.isNotEmpty) ...[
                AppSpacing.vGap8,
                _SectionTitre(
                  titre: tr('Pièces jointes'),
                  info: piecesJointesLabel(dossier.piecesJointes.length),
                ),
                _PiecesJointes(dossier: dossier),
              ],
              AppSpacing.vGap16,
              _SectionTitre(titre: tr('Suivi et réponses')),
              _Suivi(dossier: dossier),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitre extends StatelessWidget {
  final String titre;
  final String? info;

  const _SectionTitre({required this.titre, this.info});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(child: Text(titre, style: DossierText.section(context))),
          if (info != null) Text(info!, style: DossierText.petit(context)),
        ],
      ),
    );
  }
}

class _Resume extends StatelessWidget {
  final DossierModel dossier;

  const _Resume({required this.dossier});

  @override
  Widget build(BuildContext context) {
    final envoi = libelleEnvoi(dossier);
    return DossierCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DossierIconBadge(size: 36),
              AppSpacing.hGap12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dossier.titre,
                      style: AppTypography.texteSemiBold.copyWith(
                        fontSize: 17,
                        color: context.colors.primary,
                      ),
                    ),
                    if (dossier.domaineNom != null) ...[
                      AppSpacing.vGap4,
                      Text(
                        dossier.domaineNom!,
                        style: DossierText.secondaire(context),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (envoi != null) ...[
            AppSpacing.vGap12,
            Text(envoi, style: DossierText.petit(context)),
          ],
          AppSpacing.vGap12,
          DossierStatutBadge(dossier: dossier, avecIcone: true),
          if (dossier.description.isNotEmpty) ...[
            Divider(height: 28, color: context.palette.borderTinted),
            Text(
              dossier.description,
              style: AppTypography.texte.copyWith(
                fontSize: 13,
                height: 1.45,
                color: context.palette.textStrong,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// État d'un avocat sollicité, tel qu'affiché sous son nom.
String _statutAvocat(SoumissionModel s) {
  switch (s.statut) {
    case 'ACCEPTEE':
      return s.tarifPropose != null
          ? tr('A accepté · honoraires {montant}', {
              'montant': Formatters.formatFcfa(s.tarifPropose!),
            })
          : tr('A accepté votre dossier');
    case 'RETENUE':
      return tr('Avocat choisi · rendez-vous pris');
    case 'REFUSEE':
      return tr('A décliné le dossier');
    case 'CADUQUE':
      return tr('Dossier confié à un autre avocat');
    default:
      return tr('En attente de réponse');
  }
}

class _AvocatCard extends StatelessWidget {
  final DossierModel dossier;
  final SoumissionModel soumission;

  const _AvocatCard({required this.dossier, required this.soumission});

  @override
  Widget build(BuildContext context) {
    // Avocat ayant accepté (ou déjà retenu) : rendez-vous possible pour ce dossier.
    final peutReserver =
        soumission.estAcceptee &&
        soumission.tarifPropose != null &&
        soumission.avocatId.isNotEmpty;
    final motif = soumission.reponse?.trim() ?? '';

    return DossierCardContainer(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 14),
            child: DossierIconBadge(icon: Icons.balance_rounded, size: 34),
          ),
          AppSpacing.hGap12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  soumission.displayName,
                  style: AppTypography.texteSemiBold.copyWith(
                    fontSize: 14,
                    color: context.colors.primary,
                  ),
                ),
                AppSpacing.vGap4,
                Text(
                  _statutAvocat(soumission),
                  style: DossierText.petit(context),
                ),
                if (motif.isNotEmpty) ...[
                  AppSpacing.vGap4,
                  Text(
                    '« $motif »',
                    style: DossierText.petit(
                      context,
                    ).copyWith(fontStyle: FontStyle.italic),
                  ),
                ],
                if (peutReserver) ...[
                  AppSpacing.vGap8,
                  FilledButton(
                    onPressed: () => context.push(
                      AppRoutes.choixCreneau(soumission.avocatId),
                      extra: ReservationContexte.avocat(
                        professionnelId: soumission.avocatId,
                        soumissionId: soumission.id,
                        dossierTitre: dossier.titre,
                        montantDossier: soumission.tarifPropose!,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: context.palette.chip,
                      foregroundColor: context.colors.primary,
                      elevation: 0,
                      minimumSize: const Size(64, 30),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      textStyle: AppTypography.texteSemiBold.copyWith(
                        fontSize: 12,
                      ),
                    ),
                    child: Text(tr('Prendre rendez-vous')),
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

/// Encart « Pris en charge par Me … » : honoraires, détails et rendez-vous.
class _EncartPriseEnCharge extends StatelessWidget {
  final DossierModel dossier;
  final SoumissionModel soumission;

  const _EncartPriseEnCharge({required this.dossier, required this.soumission});

  @override
  Widget build(BuildContext context) {
    final honoraires = soumission.tarifPropose;
    final primary = context.colors.primary;
    return DossierCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DossierIconBadge(icon: Icons.verified_outlined, size: 34),
              AppSpacing.hGap12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('Pris en charge par {avocat}', {
                        'avocat': soumission.displayName,
                      }),
                      style: AppTypography.texteSemiBold.copyWith(
                        fontSize: 14,
                        color: primary,
                      ),
                    ),
                    if (honoraires != null) ...[
                      AppSpacing.vGap4,
                      Text(
                        tr('Honoraires proposés : {montant}', {
                          'montant': Formatters.formatFcfa(honoraires),
                        }),
                        style: DossierText.secondaire(context),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.vGap12,
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.push(
                    AppRoutes.dossierPriseEnCharge(dossier.id),
                    extra: true,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primary,
                    side: BorderSide(color: primary.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(tr('Voir les détails')),
                ),
              ),
              AppSpacing.hGap8,
              Expanded(
                child: FilledButton(
                  onPressed: honoraires == null || soumission.avocatId.isEmpty
                      ? null
                      : () => context.push(
                          AppRoutes.choixCreneau(soumission.avocatId),
                          extra: ReservationContexte.avocat(
                            professionnelId: soumission.avocatId,
                            soumissionId: soumission.id,
                            dossierTitre: dossier.titre,
                            montantDossier: honoraires,
                          ),
                        ),
                  style: FilledButton.styleFrom(
                    backgroundColor: primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(tr('Prendre rendez-vous')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PiecesJointes extends ConsumerWidget {
  final DossierModel dossier;

  const _PiecesJointes({required this.dossier});

  /// Le lien de téléchargement est temporaire : il est redemandé au serveur
  /// à chaque ouverture plutôt que repris de la liste affichée.
  Future<void> _ouvrir(
    BuildContext context,
    WidgetRef ref,
    PieceJointeModel piece,
  ) async {
    try {
      final frais = await ref
          .read(dossierRepositoryProvider)
          .getDossierById(dossier.id);
      final url = frais.piecesJointes
          .where((p) => p.id == piece.id)
          .firstOrNull
          ?.url;
      final uri = url != null ? Uri.tryParse(url) : null;
      final ouvert =
          uri != null &&
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ouvert && context.mounted) {
        AppNotification.showError(
          context,
          tr('Impossible d’ouvrir cette pièce jointe pour le moment.'),
        );
      }
    } catch (error) {
      if (context.mounted) {
        AppNotification.showError(context, userMessageFor(error));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pieces = dossier.piecesJointes;
    return DossierCardContainer(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < pieces.length; i++) ...[
            if (i > 0) Divider(height: 1, color: context.palette.borderTinted),
            InkWell(
              onTap: () => _ouvrir(context, ref, pieces[i]),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 20,
                      color: context.colors.primary,
                    ),
                    AppSpacing.hGap12,
                    Expanded(
                      child: Text(
                        pieces[i].nom,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.texte.copyWith(
                          fontSize: 13,
                          color: context.palette.textStrong,
                        ),
                      ),
                    ),
                    Text(
                      tr('Ouvrir'),
                      style: AppTypography.texteSemiBold.copyWith(
                        fontSize: 12,
                        color: context.colors.primary,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: context.colors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Étape du suivi : envoi du dossier, puis chaque réponse d'avocat.
typedef _Etape = ({IconData icone, String texte, DateTime? date});

class _Suivi extends StatelessWidget {
  final DossierModel dossier;

  const _Suivi({required this.dossier});

  List<_Etape> _etapes() {
    final etapes = <_Etape>[
      (
        icone: Icons.send_outlined,
        texte: dossier.soumissions.isEmpty
            ? tr('Dossier créé')
            : tr('Dossier envoyé aux avocats'),
        date: dossier.dateEnvoi ?? dossier.dateOuverture,
      ),
    ];
    for (final s in dossier.soumissions) {
      final etape = switch (s.statut) {
        'ACCEPTEE' => (
          icone: Icons.check_circle_outline_rounded,
          texte: tr('{avocat} a accepté votre dossier', {
            'avocat': s.displayName,
          }),
        ),
        'RETENUE' => (
          icone: Icons.event_available_outlined,
          texte: tr('Rendez-vous pris avec {avocat}', {
            'avocat': s.displayName,
          }),
        ),
        'REFUSEE' => (
          icone: Icons.cancel_outlined,
          texte: tr('{avocat} a décliné le dossier', {'avocat': s.displayName}),
        ),
        _ => null,
      };
      if (etape != null) {
        etapes.add((
          icone: etape.icone,
          texte: etape.texte,
          date: s.dateReponse,
        ));
      }
    }
    // Ordre chronologique ; une étape sans date reste en fin de liste.
    etapes.sort((a, b) {
      if (a.date == null) return b.date == null ? 0 : 1;
      if (b.date == null) return -1;
      return a.date!.compareTo(b.date!);
    });
    return etapes;
  }

  @override
  Widget build(BuildContext context) {
    final etapes = _etapes();
    return Column(
      children: [
        for (final etape in etapes) ...[
          DossierCardContainer(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(etape.icone, size: 18, color: context.colors.primary),
                AppSpacing.hGap16,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        etape.texte,
                        style: AppTypography.texteSemiBold.copyWith(
                          fontSize: 12,
                          color: context.colors.primary,
                        ),
                      ),
                      if (etape.date != null) ...[
                        AppSpacing.vGap4,
                        Text(
                          Formatters.formatDateHeure(etape.date!),
                          style: DossierText.petit(context),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.vGap8,
        ],
      ],
    );
  }
}
