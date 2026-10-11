import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/user_message.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/universe_provider.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../shared/enums/slot_status.dart';
import '../../../professionnels/data/models/creneau.dart';
import '../../../professionnels/data/models/professionnel_detail.dart';
import '../../../professionnels/presentation/controllers/professionnels_controller.dart';
import '../../data/models/reservation_contexte.dart';

/// Étape 1 du tunnel : choix d'un créneau réellement libre et du mode de consultation.
///
/// Les créneaux proviennent du backend et sont rafraîchis en temps réel ; aucun
/// créneau ni prix n'est présélectionné ou inventé par l'application.
class ChoixCreneauScreen extends ConsumerStatefulWidget {
  final String professionnelId;
  final ReservationContexte? contexte;

  const ChoixCreneauScreen({
    super.key,
    required this.professionnelId,
    required this.contexte,
  });

  @override
  ConsumerState<ChoixCreneauScreen> createState() => _ChoixCreneauScreenState();
}

class _ChoixCreneauScreenState extends ConsumerState<ChoixCreneauScreen> {
  DateTime? _jour;
  Creneau? _creneau;
  String? _mode;
  final _motifController = TextEditingController();

  @override
  void dispose() {
    _motifController.dispose();
    super.dispose();
  }

  /// Modes proposés par le professionnel (codes backend : VISIO, CABINET).
  List<String> _modesDe(ProfessionnelDetail pro) {
    final code = pro.summary.modeConsultation?.toUpperCase() ?? '';
    final modes = <String>[
      if (code.contains('VISIO')) 'VISIO',
      if (code.contains('CABINET')) 'CABINET',
    ];
    // Mode non renseigné par le professionnel : les deux modes acceptés par le backend.
    return modes.isEmpty ? const ['VISIO', 'CABINET'] : modes;
  }

  @override
  Widget build(BuildContext context) {
    final universe = ref.watch(currentUniverseProvider);
    final primaryColor = universe.primaryColor;
    final contexte = widget.contexte;
    final proAsync = ref.watch(professionnelDetailProvider(widget.professionnelId));
    final creneauxAsync = ref.watch(creneauxProvider(widget.professionnelId));

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Choisir un créneau',
          style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF111827)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: contexte == null
          ? const AppErrorStateView(
              title: 'Réservation indisponible',
              message: 'Ouvrez la fiche du professionnel pour choisir une consultation.',
            )
          : proAsync.when(
              loading: () => AppLoadingView(universe: universe),
              error: (e, _) => AppErrorStateView(
                message: userMessageFor(e),
                onRetry: () => ref.invalidate(professionnelDetailProvider(widget.professionnelId)),
              ),
              data: (pro) => creneauxAsync.when(
                loading: () => AppLoadingView(
                  universe: universe,
                  message: 'Chargement des disponibilités…',
                ),
                error: (e, _) => AppErrorStateView(
                  message: userMessageFor(e),
                  onRetry: () => ref.invalidate(creneauxProvider(widget.professionnelId)),
                ),
                data: (creneaux) => _buildContenu(context, pro, creneaux, contexte, primaryColor),
              ),
            ),
    );
  }

  Widget _buildContenu(
    BuildContext context,
    ProfessionnelDetail pro,
    List<Creneau> creneaux,
    ReservationContexte contexte,
    Color primaryColor,
  ) {
    final maintenant = DateTime.now();
    final libres = creneaux
        .where((c) => c.statut == SlotStatus.libre && c.debut.isAfter(maintenant))
        .toList();

    if (libres.isEmpty) {
      return AppEmptyStateView(
        icon: Icons.event_busy_rounded,
        title: 'Aucun créneau disponible',
        message: '${pro.summary.displayName} n’a pas de créneau libre pour le moment. '
            'Les nouvelles disponibilités apparaîtront ici automatiquement.',
      );
    }

    final jours = <DateTime>{for (final c in libres) c.jour}.toList()..sort();
    // Le créneau choisi a pu être pris entre-temps (mise à jour temps réel).
    if (_creneau != null && !libres.any((c) => c.id == _creneau!.id)) {
      _creneau = null;
    }
    final jourActif = _jour != null && jours.contains(_jour) ? _jour! : jours.first;
    final creneauxDuJour = libres.where((c) => c.jour == jourActif).toList();
    final modes = _modesDe(pro);
    final modeChoisi = _mode != null && modes.contains(_mode) ? _mode : (modes.length == 1 ? modes.first : null);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              _EnTeteProfessionnel(pro: pro, contexte: contexte, primaryColor: primaryColor),
              const SizedBox(height: 24),
              const _Titre('Date'),
              const SizedBox(height: 12),
              SizedBox(
                height: 76,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: jours.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final jour = jours[i];
                    final actif = jour == jourActif;
                    return _Puce(
                      actif: actif,
                      primaryColor: primaryColor,
                      onTap: () => setState(() {
                        _jour = jour;
                        _creneau = null;
                      }),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            Formatters.formatJourCourt(jour),
                            style: TextStyle(fontSize: 12, color: actif ? Colors.white : const Color(0xFF6B7280)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${jour.day}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: actif ? Colors.white : const Color(0xFF111827),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              _Titre('Créneaux du ${Formatters.formatJourLong(jourActif)}'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: creneauxDuJour.map((c) {
                  final actif = _creneau?.id == c.id;
                  return _Puce(
                    actif: actif,
                    primaryColor: primaryColor,
                    largeur: 92,
                    hauteur: 44,
                    onTap: () => setState(() => _creneau = c),
                    child: Text(
                      Formatters.formatHeure(c.debut),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: actif ? Colors.white : const Color(0xFF111827),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              const _Titre('Mode de consultation'),
              const SizedBox(height: 12),
              RadioGroup<String>(
                groupValue: modeChoisi,
                onChanged: (v) => setState(() => _mode = v),
                child: Column(
                  children: modes
                      .map(
                        (m) => RadioListTile<String>(
                          value: m,
                          activeColor: primaryColor,
                          contentPadding: EdgeInsets.zero,
                          title: Text(m == 'VISIO' ? 'En visioconférence' : 'Au cabinet'),
                          subtitle: m == 'CABINET' && (pro.adresse?.isNotEmpty ?? false)
                              ? Text(pro.adresse!, maxLines: 2, overflow: TextOverflow.ellipsis)
                              : null,
                        ),
                      )
                      .toList(),
                ),
              ),
              if (!contexte.viaDossier) ...[
                const SizedBox(height: 16),
                const _Titre('Motif (facultatif)'),
                const SizedBox(height: 8),
                TextField(
                  controller: _motifController,
                  maxLines: 3,
                  maxLength: 500,
                  decoration: InputDecoration(
                    hintText: 'Précisez en quelques mots l’objet de la consultation',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ],
          ),
        ),
        _BarreAction(
          primaryColor: primaryColor,
          montant: contexte.montantTotal,
          libelle: contexte.libelleMontant,
          actif: _creneau != null && modeChoisi != null,
          onPressed: () => context.push(
            AppRoutes.rendezVousConfirmation,
            extra: ReservationRecap(
              contexte: contexte,
              professionnel: pro,
              creneau: _creneau!,
              mode: modeChoisi!,
              motif: _motifController.text,
            ),
          ),
        ),
      ],
    );
  }
}

class _EnTeteProfessionnel extends StatelessWidget {
  final ProfessionnelDetail pro;
  final ReservationContexte contexte;
  final Color primaryColor;

  const _EnTeteProfessionnel({required this.pro, required this.contexte, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    final photo = pro.summary.photoUrl;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: primaryColor.withValues(alpha: 0.12),
            backgroundImage: photo != null ? NetworkImage(photo) : null,
            child: photo == null
                ? Icon(pro.summary.isAvocat ? Icons.gavel_rounded : Icons.psychology_rounded, color: primaryColor)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pro.summary.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  contexte.viaDossier
                      ? 'Dossier : ${contexte.dossierTitre ?? ''}'
                      : (pro.specialites.isNotEmpty ? pro.specialites.first.nom : pro.summary.type ?? ''),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Titre extends StatelessWidget {
  final String texte;
  const _Titre(this.texte);

  @override
  Widget build(BuildContext context) {
    return Text(
      texte,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
    );
  }
}

class _Puce extends StatelessWidget {
  final bool actif;
  final Color primaryColor;
  final VoidCallback onTap;
  final Widget child;
  final double largeur;
  final double hauteur;

  const _Puce({
    required this.actif,
    required this.primaryColor,
    required this.onTap,
    required this.child,
    this.largeur = 60,
    this.hauteur = 76,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: largeur,
        height: hauteur,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: actif ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: actif ? primaryColor : const Color(0xFFE5E7EB)),
        ),
        child: child,
      ),
    );
  }
}

class _BarreAction extends StatelessWidget {
  final Color primaryColor;
  final double montant;
  final String libelle;
  final bool actif;
  final VoidCallback onPressed;

  const _BarreAction({
    required this.primaryColor,
    required this.montant,
    required this.libelle,
    required this.actif,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(libelle, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      Formatters.formatFcfa(montant),
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: primaryColor),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: AppButton(
                text: 'Continuer',
                onPressed: actif ? onPressed : null,
                color: primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
