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
import '../../../professionnels/presentation/widgets/availability_picker.dart';
import '../../data/models/reservation_contexte.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/l10n/app_strings.dart';

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
  late Creneau? _creneau = widget.contexte?.creneauPropose;
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
    final primaryColor = Theme.of(context).colorScheme.primary;
    final contexte = widget.contexte;
    final proAsync = ref.watch(
      professionnelDetailProvider(widget.professionnelId),
    );
    final creneauxAsync = ref.watch(creneauxProvider(widget.professionnelId));

    return Scaffold(
      backgroundColor: context.palette.page,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          tr('Choisir un créneau'),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: context.palette.textStrong,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: contexte == null
          ? AppErrorStateView(
              title: tr('Réservation indisponible'),
              message: tr(
                'Ouvrez la fiche du professionnel pour choisir une consultation.',
              ),
            )
          : proAsync.when(
              loading: () => AppLoadingView(universe: universe),
              error: (e, _) => AppErrorStateView(
                message: userMessageFor(e),
                onRetry: () => ref.invalidate(
                  professionnelDetailProvider(widget.professionnelId),
                ),
              ),
              data: (pro) => creneauxAsync.when(
                loading: () => AppLoadingView(
                  universe: universe,
                  message: tr('Chargement des disponibilités…'),
                ),
                error: (e, _) => AppErrorStateView(
                  message: userMessageFor(e),
                  onRetry: () =>
                      ref.invalidate(creneauxProvider(widget.professionnelId)),
                ),
                data: (creneaux) => _buildContenu(
                  context,
                  pro,
                  creneaux,
                  contexte,
                  primaryColor,
                ),
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
        .where(
          (c) => c.statut == SlotStatus.libre && c.debut.isAfter(maintenant),
        )
        .toList();

    if (libres.isEmpty) {
      return AppEmptyStateView(
        icon: Icons.event_busy_rounded,
        title: tr('Aucun créneau disponible'),
        message: tr(
          '{pro} n’a pas de créneau libre pour le moment. '
          'Les nouvelles disponibilités apparaîtront ici automatiquement.',
          {'pro': pro.summary.displayName},
        ),
      );
    }

    // Le créneau choisi a pu être pris entre-temps (mise à jour temps réel).
    if (_creneau != null && !libres.any((c) => c.id == _creneau!.id)) {
      _creneau = null;
    }
    final modes = _modesDe(pro);
    final modeChoisi = _mode != null && modes.contains(_mode)
        ? _mode
        : (modes.length == 1 ? modes.first : null);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              _EnTeteProfessionnel(
                pro: pro,
                contexte: contexte,
                primaryColor: primaryColor,
              ),
              const SizedBox(height: 24),
              _Titre(tr('Date et heure')),
              const SizedBox(height: 12),
              AvailabilityPicker(
                creneaux: creneaux,
                primaryColor: primaryColor,
                guide: tr(
                  'Choisissez une date (les jours marqués d’un point vert ont des '
                  'créneaux libres), puis touchez l’heure qui vous convient.',
                ),
                selected: _creneau,
                onSelected: (c) => setState(() => _creneau = c),
              ),
              const SizedBox(height: 24),
              _Titre(tr('Mode de consultation')),
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
                          title: Text(
                            m == 'VISIO'
                                ? tr('En visioconférence')
                                : tr('Au cabinet'),
                          ),
                          subtitle:
                              m == 'CABINET' &&
                                  (pro.adresse?.isNotEmpty ?? false)
                              ? Text(
                                  pro.adresse!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : null,
                        ),
                      )
                      .toList(),
                ),
              ),
              if (!contexte.viaDossier) ...[
                const SizedBox(height: 16),
                _Titre(tr('Motif (facultatif)')),
                const SizedBox(height: 8),
                TextField(
                  controller: _motifController,
                  maxLines: 3,
                  maxLength: 500,
                  decoration: InputDecoration(
                    hintText: tr(
                      'Précisez en quelques mots l’objet de la consultation',
                    ),
                    filled: true,
                    fillColor: context.palette.card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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

  const _EnTeteProfessionnel({
    required this.pro,
    required this.contexte,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final photo = pro.summary.photoUrl;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.palette.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: primaryColor.withValues(alpha: 0.12),
            backgroundImage: photo != null ? NetworkImage(photo) : null,
            child: photo == null
                ? Icon(
                    pro.summary.isAvocat
                        ? Icons.gavel_rounded
                        : Icons.psychology_rounded,
                    color: primaryColor,
                  )
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  contexte.viaDossier
                      ? tr('Dossier : {titre}', {
                          'titre': contexte.dossierTitre ?? '',
                        })
                      : (pro.specialites.isNotEmpty
                            ? pro.specialites.first.nom
                            : pro.summary.type ?? ''),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: context.palette.textMuted,
                  ),
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
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: context.palette.textStrong,
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
        child: Row(
          children: [
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    libelle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.palette.textMuted,
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      Formatters.formatFcfa(montant),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: AppButton(
                text: tr('Continuer'),
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
