import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/user_message.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../data/models/rendez_vous_model.dart';
import '../../data/models/reservation_contexte.dart';
import '../controllers/rendez_vous_controller.dart';
import '../widgets/recap_rendez_vous.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/widgets/app_back_button.dart';

/// Étape 2 du tunnel : récapitulatif, paiement SIMULÉ de l'acompte (V1) et confirmation.
///
/// Aucune passerelle de paiement n'est intégrée : aucune donnée bancaire n'est
/// demandée ni stockée, et l'utilisateur coche explicitement qu'il s'agit d'une
/// simulation. Le rendez-vous n'est affiché comme confirmé qu'après la réponse
/// du backend (créneau revérifié sous verrou, montant et acompte calculés côté serveur).
class RendezVousConfirmationScreen extends ConsumerStatefulWidget {
  final ReservationRecap? recap;

  const RendezVousConfirmationScreen({super.key, required this.recap});

  @override
  ConsumerState<RendezVousConfirmationScreen> createState() =>
      _RendezVousConfirmationScreenState();
}

class _RendezVousConfirmationScreenState
    extends ConsumerState<RendezVousConfirmationScreen> {
  bool _simulationAcceptee = false;
  bool _enCours = false;
  String? _erreur;
  bool _creneauPerdu = false;
  RendezVous? _confirme;

  Future<void> _confirmer(ReservationRecap recap) async {
    setState(() {
      _enCours = true;
      _erreur = null;
      _creneauPerdu = false;
    });
    try {
      final rdv = await ref
          .read(rendezVousControllerProvider.notifier)
          .reserver(recap);
      if (!mounted) return;
      setState(() => _confirme = rdv);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _erreur = userMessageFor(error);
        _creneauPerdu =
            error is ConflictException ||
            (error is ValidationException &&
                (error.message.contains('créneau')));
      });
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  /// « Avocat · Droit pénal » : métier et première spécialité.
  String _sousTitre(ReservationRecap recap) {
    final s = recap.professionnel.summary;
    return [
      s.isAvocat ? tr('Avocat') : tr('Psychologue'),
      if (s.specialites.isNotEmpty) s.specialites.first,
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final recap = widget.recap;

    if (recap == null) {
      return Scaffold(
        appBar: AppBar(leading: const AppBackButton()),
        body: AppErrorStateView(
          title: tr('Réservation indisponible'),
          message: tr(
            'Choisissez d’abord un créneau depuis la fiche du professionnel.',
          ),
        ),
      );
    }

    final confirme = _confirme;
    return PopScope(
      canPop: !_enCours,
      child: Scaffold(
        backgroundColor: context.palette.page,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          // Pas de retour pendant le paiement ni après la confirmation.
          automaticallyImplyLeading: false,
          leading: confirme == null && !_enCours ? const AppBackButton() : null,
          title: Text(
            confirme == null
                ? tr('Confirmer le rendez-vous')
                : tr('Rendez-vous confirmé'),
          ),
        ),
        body: confirme != null
            ? _Succes(
                rdv: confirme,
                recap: recap,
                sousTitre: _sousTitre(recap),
                primaryColor: primaryColor,
              )
            : _buildRecapitulatif(context, recap, primaryColor),
      ),
    );
  }

  Widget _buildRecapitulatif(
    BuildContext context,
    ReservationRecap recap,
    Color primaryColor,
  ) {
    final pro = recap.professionnel;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              RecapRendezVousCard(
                professionnelNom: pro.summary.displayName,
                photoUrl: pro.summary.photoUrl,
                sousTitre: _sousTitre(recap),
                debut: recap.creneau.debut,
                fin: recap.creneau.fin,
                mode: recap.mode,
                adresse: pro.adresse,
                dossierTitre: recap.contexte.viaDossier
                    ? recap.contexte.dossierTitre
                    : null,
              ),
              const SizedBox(height: 14),
              RecapMontantsCard(
                total: recap.montantTotal,
                libelleTotal: recap.contexte.libelleMontant,
                acompte: recap.acompteEstime,
                libelleAcompte: tr('Acompte à régler (20 %)'),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: _simulationAcceptee,
                onChanged: _enCours
                    ? null
                    : (v) => setState(() => _simulationAcceptee = v ?? false),
                activeColor: primaryColor,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  tr(
                    'Je comprends que ce paiement est une simulation et qu’aucune somme ne sera débitée.',
                  ),
                  style: TextStyle(fontSize: 13, color: context.palette.text),
                ),
              ),
              if (_erreur != null) ...[
                const SizedBox(height: 8),
                _MessageErreur(message: _erreur!),
                if (_creneauPerdu)
                  AppButton.ghost(
                    text: tr('Choisir un autre créneau'),
                    onPressed: () => context.pop(),
                  ),
              ],
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          color: context.palette.card,
          child: SafeArea(
            top: false,
            child: AppButton(
              text: tr('Simuler le paiement et confirmer'),
              isLoading: _enCours,
              onPressed: _simulationAcceptee && !_enCours
                  ? () => _confirmer(recap)
                  : null,
              color: primaryColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _Succes extends StatelessWidget {
  final RendezVous rdv;
  final ReservationRecap recap;
  final String sousTitre;
  final Color primaryColor;

  const _Succes({
    required this.rdv,
    required this.recap,
    required this.sousTitre,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    // Valeurs faisant foi : celles renvoyées par le backend.
    final total = rdv.montantTotal ?? recap.montantTotal;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            children: [
              Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.6, end: 1),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutBack,
                  builder: (context, echelle, child) =>
                      Transform.scale(scale: echelle, child: child),
                  child: Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.event_available_rounded,
                        size: 36,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                tr('Votre rendez-vous est confirmé'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: context.palette.textStrong,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                tr(
                  '{pro} a été prévenu. Un rappel vous sera envoyé avant le rendez-vous.',
                  {'pro': recap.professionnel.summary.displayName},
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: context.palette.text,
                ),
              ),
              const SizedBox(height: 22),
              RecapRendezVousCard(
                professionnelNom: recap.professionnel.summary.displayName,
                photoUrl:
                    rdv.professionnelPhotoUrl ??
                    recap.professionnel.summary.photoUrl,
                sousTitre: sousTitre,
                debut: rdv.dateHeure,
                fin: rdv.fin,
                mode: rdv.mode ?? recap.mode,
                adresse: rdv.adresseCabinet ?? recap.professionnel.adresse,
                dossierTitre: rdv.dossierTitre ?? recap.contexte.dossierTitre,
              ),
              const SizedBox(height: 14),
              RecapMontantsCard(
                total: total,
                libelleTotal: tr('Montant total'),
                acompte: rdv.montantAcompte,
                libelleAcompte: tr('Acompte réglé (20 %)'),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          color: context.palette.page,
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                AppButton(
                  text: tr('Voir mes rendez-vous'),
                  icon: Icons.event_note_rounded,
                  color: primaryColor,
                  onPressed: () => context.go(AppRoutes.rendezVous),
                ),
                const SizedBox(height: 10),
                AppButton(
                  text: tr('Terminé'),
                  isOutlined: true,
                  color: primaryColor,
                  onPressed: () => context.go(AppRoutes.home),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MessageErreur extends StatelessWidget {
  final String message;
  const _MessageErreur({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFF991B1B)),
            ),
          ),
        ],
      ),
    );
  }
}
