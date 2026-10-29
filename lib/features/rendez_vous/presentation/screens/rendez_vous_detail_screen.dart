import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/user_message.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/theme/universe_provider.dart';
import '../../../../core/utils/visio.dart';
import '../../../../core/widgets/app_alert.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../shared/enums/appointment_status.dart';
import '../../../paiements/presentation/widgets/recu_paiement_sheet.dart';
import '../../../profile/presentation/controllers/profil_controller.dart';
import '../../data/models/rendez_vous_model.dart';
import '../controllers/rendez_vous_controller.dart';
import '../widgets/annuler_rendez_vous_dialog.dart';
import '../widgets/recap_rendez_vous.dart';

/// Détail d'un rendez-vous, en page plein écran (au-dessus de la barre de
/// navigation) : récapitulatif, paiement, visioconférence et dossier.
/// L'annulation est proposée dans le menu « ⋮ » de la barre du haut.
class RendezVousDetailScreen extends ConsumerStatefulWidget {
  final String rendezVousId;

  /// Rendez-vous déjà chargé par la liste (affichage immédiat).
  final RendezVous? initial;

  const RendezVousDetailScreen({
    super.key,
    required this.rendezVousId,
    this.initial,
  });

  @override
  ConsumerState<RendezVousDetailScreen> createState() =>
      _RendezVousDetailScreenState();
}

class _RendezVousDetailScreenState
    extends ConsumerState<RendezVousDetailScreen> {
  bool _annulation = false;

  /// Version à jour : celle de la liste (temps réel), sinon le chargement direct.
  RendezVous? _depuisListe() {
    final liste = ref.watch(rendezVousControllerProvider).value;
    return liste?.where((r) => r.id == widget.rendezVousId).firstOrNull;
  }

  Future<void> _annuler(RendezVous rdv) async {
    final choix = await showAnnulerRendezVousDialog(context, rdv);
    if (choix == null || !mounted) return;
    setState(() => _annulation = true);
    try {
      await ref
          .read(rendezVousControllerProvider.notifier)
          .annuler(rdv.id, motif: choix.motif);
      if (!mounted) return;
      AppNotification.showSuccess(
        context,
        tr('Rendez-vous annulé. {pro} a été prévenu.', {
          'pro': rdv.professionnelDisplayName,
        }),
      );
      context.pop();
    } catch (error) {
      if (mounted) AppNotification.showError(context, userMessageFor(error));
    } finally {
      if (mounted) setState(() => _annulation = false);
    }
  }

  Future<void> _rejoindreVisio(String lien) async {
    final profil = ref.read(currentProfilProvider).value;
    final nom = profil == null ? null : '${profil.prenom} ${profil.nom}';
    final ouvert = await rejoindreVisio(lien, nom: nom);
    if (!ouvert && mounted) {
      AppNotification.showError(
        context,
        tr('Impossible d’ouvrir le lien de visioconférence.'),
      );
    }
  }

  void _afficherRecuAcompte(RendezVous rdv) {
    final total = rdv.montantTotal ?? 0;
    final acompte = rdv.montantAcompte ?? (total * 0.2);
    showRecuPaiementSheet(
      context,
      RecuPaiementData(
        referenceId: rdv.id,
        professionnelNom: rdv.professionnelDisplayName,
        typeProfessionnel: rdv.typeProfessionnel,
        dateRendezVous: rdv.dateHeure,
        datePaiement: rdv.dateHeure,
        montantAcompte: acompte,
        montantTotal: total,
        estAnnule:
            rdv.statut == AppointmentStatus.annule ||
            rdv.statutPaiement?.toUpperCase() == 'ANNULE',
        simulation: true,
        modeConsultation: rdv.mode == 'VISIO'
            ? tr('Visioconférence')
            : tr('En cabinet'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final universe = ref.watch(currentUniverseProvider);
    final rdv = _depuisListe() ?? widget.initial;

    return Scaffold(
      backgroundColor: context.palette.page,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const AppBackButton(),
        title: Text(tr('Détail du rendez-vous')),
        actions: [
          // Annulation : discrète, dans le menu, tant que c'est possible.
          if (rdv != null && rdv.canBeChangedAt(DateTime.now()))
            PopupMenuButton<String>(
              tooltip: tr('Plus d’actions'),
              enabled: !_annulation,
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (_) => _annuler(rdv),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'annuler',
                  child: ListTile(
                    leading: const Icon(
                      Icons.event_busy_outlined,
                      color: AppColors.danger,
                    ),
                    title: Text(tr('Annuler ce rendez-vous')),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
        ],
      ),
      body: rdv != null
          ? _contenu(context, rdv)
          : ref
                .watch(rendezVousDetailProvider(widget.rendezVousId))
                .when(
                  loading: () => AppLoadingView(universe: universe),
                  error: (e, _) => AppErrorStateView(
                    title: tr('Rendez-vous indisponible'),
                    message: userMessageFor(e),
                    onRetry: () => ref.invalidate(
                      rendezVousDetailProvider(widget.rendezVousId),
                    ),
                  ),
                  data: (charge) => _contenu(context, charge),
                ),
    );
  }

  Widget _contenu(BuildContext context, RendezVous rdv) {
    final scheme = Theme.of(context).colorScheme;
    final maintenant = DateTime.now();
    final lienVisio = rdv.lienVisio;
    final afficherVisio =
        lienVisio != null &&
        lienVisio.isNotEmpty &&
        rdv.statut != AppointmentStatus.annule &&
        rdv.fin.isAfter(maintenant);
    final couleurStatut = rdv.statut.color(scheme);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        RecapRendezVousCard(
          professionnelNom: rdv.professionnelDisplayName,
          photoUrl: rdv.professionnelPhotoUrl,
          sousTitre: [
            rdv.typeLabel,
            if (rdv.professionnelSpecialite?.isNotEmpty ?? false)
              rdv.professionnelSpecialite!,
          ].join(' · '),
          debut: rdv.dateHeure,
          fin: rdv.fin,
          mode: rdv.mode,
          adresse: rdv.adresseCabinet,
          dossierTitre: rdv.dossierTitre,
          statut: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: couleurStatut.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              rdv.statut.label,
              style: AppTypography.texteSemiBold.copyWith(
                fontSize: 11,
                color: couleurStatut,
              ),
            ),
          ),
        ),
        if (rdv.motif?.trim().isNotEmpty ?? false) ...[
          const SizedBox(height: 12),
          _Bloc(
            icone: Icons.notes_rounded,
            titre: tr('Motif de consultation'),
            texte: rdv.motif!.trim(),
          ),
        ],
        if (rdv.montantTotal != null) ...[
          const SizedBox(height: 12),
          RecapMontantsCard(
            total: rdv.montantTotal!,
            libelleTotal: tr('Montant total'),
            acompte: rdv.montantAcompte,
            libelleAcompte: tr('Acompte (20 %)'),
            etat: switch (rdv.statutPaiement?.toUpperCase()) {
              'PAYE' => tr('Acompte réglé'),
              'ANNULE' => tr('Acompte annulé'),
              _ => null,
            },
          ),
          const SizedBox(height: 10),
          AppButton(
            text: tr('Voir le reçu officiel d’acompte (20 %)'),
            icon: Icons.receipt_long_rounded,
            isOutlined: true,
            color: scheme.primary,
            onPressed: () => _afficherRecuAcompte(rdv),
          ),
        ],
        const SizedBox(height: 20),
        if (afficherVisio) ...[
          AppButton(
            text: tr('Rejoindre la visioconférence'),
            icon: Icons.videocam_rounded,
            color: scheme.primary,
            onPressed: () => _rejoindreVisio(lienVisio),
          ),
          const SizedBox(height: 10),
        ],
        if (rdv.dossierId != null) ...[
          AppButton(
            text: tr('Voir le dossier'),
            icon: Icons.folder_open_rounded,
            isOutlined: true,
            color: scheme.primary,
            onPressed: () =>
                context.push(AppRoutes.dossierPriseEnCharge(rdv.dossierId!)),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _Bloc extends StatelessWidget {
  final IconData icone;
  final String titre;
  final String texte;

  const _Bloc({required this.icone, required this.titre, required this.texte});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, size: 18, color: primary),
              const SizedBox(width: 8),
              Text(
                titre,
                style: AppTypography.texteSemiBold.copyWith(
                  fontSize: 15,
                  color: context.palette.textStrong,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            texte,
            style: AppTypography.texte.copyWith(
              fontSize: 14,
              height: 1.45,
              color: context.palette.text,
            ),
          ),
        ],
      ),
    );
  }
}
