import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/user_message.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/universe_provider.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../data/models/rendez_vous_model.dart';
import '../../data/models/reservation_contexte.dart';
import '../controllers/rendez_vous_controller.dart';

/// Étape 2 du tunnel : récapitulatif, paiement SIMULÉ de l'acompte (V1) et confirmation.
///
/// Aucune passerelle de paiement n'est intégrée : l'étape de paiement est
/// présentée explicitement comme une simulation, aucune donnée bancaire n'est
/// demandée ni stockée. Le rendez-vous n'est affiché comme confirmé qu'après la
/// réponse du backend (créneau revérifié sous verrou, montant et acompte calculés
/// côté serveur).
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
        _creneauPerdu = error is ConflictException ||
            (error is ValidationException && (error.message.contains('créneau')));
      });
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final universe = ref.watch(currentUniverseProvider);
    final primaryColor = universe.primaryColor;
    final recap = widget.recap;

    if (recap == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const AppErrorStateView(
          title: 'Réservation indisponible',
          message: 'Choisissez d’abord un créneau depuis la fiche du professionnel.',
        ),
      );
    }

    final confirme = _confirme;
    return PopScope(
      canPop: !_enCours,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFC),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: confirme == null && !_enCours,
          title: Text(
            confirme == null ? 'Confirmer le rendez-vous' : 'Rendez-vous confirmé',
            style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF111827)),
          ),
        ),
        body: confirme != null
            ? _Succes(rdv: confirme, recap: recap, primaryColor: primaryColor)
            : _buildRecapitulatif(context, recap, primaryColor),
      ),
    );
  }

  Widget _buildRecapitulatif(BuildContext context, ReservationRecap recap, Color primaryColor) {
    final pro = recap.professionnel;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              _Carte(
                children: [
                  _Ligne(icone: Icons.person_outline_rounded, libelle: 'Professionnel', valeur: pro.summary.displayName),
                  if (recap.contexte.viaDossier)
                    _Ligne(icone: Icons.folder_outlined, libelle: 'Dossier', valeur: recap.contexte.dossierTitre ?? ''),
                  _Ligne(
                    icone: Icons.calendar_today_rounded,
                    libelle: 'Date',
                    valeur: Formatters.formatJourLong(recap.creneau.debut),
                  ),
                  _Ligne(
                    icone: Icons.schedule_rounded,
                    libelle: 'Heure',
                    valeur: '${Formatters.formatHeure(recap.creneau.debut)} – ${Formatters.formatHeure(recap.creneau.fin)}',
                  ),
                  _Ligne(
                    icone: recap.mode == 'VISIO' ? Icons.videocam_outlined : Icons.location_on_outlined,
                    libelle: 'Mode',
                    valeur: recap.mode == 'VISIO'
                        ? 'En visioconférence'
                        : 'Au cabinet${(pro.adresse?.isNotEmpty ?? false) ? ' — ${pro.adresse}' : ''}',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _Carte(
                children: [
                  _Ligne(icone: Icons.receipt_long_outlined, libelle: recap.contexte.libelleMontant,
                      valeur: Formatters.formatFcfa(recap.montantTotal)),
                  _Ligne(
                    icone: Icons.account_balance_wallet_outlined,
                    libelle: 'Acompte à régler (20 %)',
                    valeur: Formatters.formatFcfa(recap.acompteEstime),
                    accent: primaryColor,
                  ),
                  _Ligne(
                    icone: Icons.info_outline_rounded,
                    libelle: 'Reste à régler au professionnel',
                    valeur: Formatters.formatFcfa(recap.montantTotal - recap.acompteEstime),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _AvertissementSimulation(primaryColor: primaryColor),
              CheckboxListTile(
                value: _simulationAcceptee,
                onChanged: _enCours ? null : (v) => setState(() => _simulationAcceptee = v ?? false),
                activeColor: primaryColor,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text(
                  'Je comprends que ce paiement est une simulation et qu’aucune somme ne sera débitée.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
              if (_erreur != null) ...[
                const SizedBox(height: 8),
                _MessageErreur(message: _erreur!),
                if (_creneauPerdu)
                  TextButton.icon(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.event_available_rounded),
                    label: const Text('Choisir un autre créneau'),
                  ),
              ],
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          color: Colors.white,
          child: SafeArea(
            top: false,
            child: AppButton(
              text: 'Simuler le paiement et confirmer',
              isLoading: _enCours,
              onPressed: _simulationAcceptee && !_enCours ? () => _confirmer(recap) : null,
              color: primaryColor,
            ),
          ),
        ),
      ],
    );
  }
}

/// Mention explicite : V1 sans prestataire de paiement.
class _AvertissementSimulation extends StatelessWidget {
  final Color primaryColor;
  const _AvertissementSimulation({required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.science_outlined, color: Color(0xFFC2410C)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Paiement simulé : aucune transaction réelle n’est effectuée et aucune '
              'donnée bancaire n’est demandée. Le paiement en ligne sera disponible ultérieurement.',
              style: TextStyle(fontSize: 13, color: Color(0xFF7C2D12), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _Succes extends StatelessWidget {
  final RendezVous rdv;
  final ReservationRecap recap;
  final Color primaryColor;

  const _Succes({required this.rdv, required this.recap, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    // Valeurs faisant foi : celles renvoyées par le backend.
    final acompte = rdv.montantAcompte;
    final total = rdv.montantTotal ?? recap.montantTotal;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Icon(Icons.check_circle_rounded, color: primaryColor, size: 72),
        const SizedBox(height: 16),
        const Text(
          'Votre rendez-vous est confirmé',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          '${recap.professionnel.summary.displayName} — ${Formatters.formatJourLong(rdv.dateHeure)} à ${Formatters.formatHeure(rdv.dateHeure)}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF4B5563)),
        ),
        const SizedBox(height: 24),
        _Carte(
          children: [
            _Ligne(icone: Icons.receipt_long_outlined, libelle: 'Montant total', valeur: Formatters.formatFcfa(total)),
            if (acompte != null)
              _Ligne(
                icone: Icons.science_outlined,
                libelle: 'Acompte (paiement simulé)',
                valeur: Formatters.formatFcfa(acompte),
                accent: primaryColor,
              ),
          ],
        ),
        const SizedBox(height: 28),
        AppButton(
          text: 'Voir mes rendez-vous',
          color: primaryColor,
          onPressed: () => context.go(AppRoutes.rendezVous),
        ),
        const SizedBox(height: 12),
        AppButton(
          text: 'Retour à l’accueil',
          isOutlined: true,
          color: primaryColor,
          onPressed: () => context.go(AppRoutes.home),
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(children: children),
    );
  }
}

class _Ligne extends StatelessWidget {
  final IconData icone;
  final String libelle;
  final String valeur;
  final Color? accent;

  const _Ligne({required this.icone, required this.libelle, required this.valeur, this.accent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, size: 20, color: const Color(0xFF6B7280)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(libelle, style: const TextStyle(fontSize: 14, color: Color(0xFF4B5563))),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              valeur,
              textAlign: TextAlign.end,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: accent ?? const Color(0xFF111827)),
            ),
          ),
        ],
      ),
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
          Expanded(child: Text(message, style: const TextStyle(color: Color(0xFF991B1B)))),
        ],
      ),
    );
  }
}
