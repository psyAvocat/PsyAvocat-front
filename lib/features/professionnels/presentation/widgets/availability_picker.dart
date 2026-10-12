import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/enums/slot_status.dart';
import '../../data/models/creneau.dart';
import '../../../../core/l10n/app_strings.dart';

/// Sélecteur de disponibilités : une semaine à la fois (flèches ou glissement),
/// une pastille sous chaque jour qui a des créneaux libres, puis les créneaux
/// du jour choisi, regroupés par moment de la journée.
///
/// Un guide et une légende expliquent les variantes de créneaux : disponible
/// (sélectionnable), sélectionné, indisponible (réservé, bloqué ou passé).
/// Sans [onSelected], le sélecteur sert seulement à consulter.
class AvailabilityPicker extends StatefulWidget {
  /// Tous les créneaux du professionnel, quel que soit leur statut.
  final List<Creneau> creneaux;
  final Color primaryColor;
  final Creneau? selected;
  final ValueChanged<Creneau>? onSelected;

  /// Consigne affichée en tête (ex. « Choisissez une date, puis un créneau »).
  final String guide;

  const AvailabilityPicker({
    super.key,
    required this.creneaux,
    required this.primaryColor,
    required this.guide,
    this.selected,
    this.onSelected,
  });

  @override
  State<AvailabilityPicker> createState() => _AvailabilityPickerState();
}

/// Nombre maximal de semaines proposées à partir de la semaine courante.
const _semainesMax = 12;

DateTime _jourDe(DateTime d) => DateTime(d.year, d.month, d.day);

/// Lundi de la semaine qui contient [d].
DateTime _lundiDe(DateTime d) =>
    _jourDe(d).subtract(Duration(days: d.weekday - 1));

class _AvailabilityPickerState extends State<AvailabilityPicker> {
  late final DateTime _premierLundi = _lundiDe(DateTime.now());
  late final PageController _pages;
  late DateTime _jour;
  late int _semaine;

  @override
  void initState() {
    super.initState();
    _jour = _premierJourLibre() ?? _jourDe(DateTime.now());
    _semaine = _semaineDe(_jour);
    _pages = PageController(initialPage: _semaine);
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  bool _estLibre(Creneau c) =>
      c.statut == SlotStatus.libre && c.debut.isAfter(DateTime.now());

  DateTime? _premierJourLibre() {
    final libres = widget.creneaux.where(_estLibre).map((c) => c.jour).toList()
      ..sort();
    return libres.firstOrNull;
  }

  int _semaineDe(DateTime jour) =>
      (_lundiDe(jour).difference(_premierLundi).inDays / 7).round().clamp(
        0,
        _nombreSemaines - 1,
      );

  /// De la semaine courante jusqu'à celle du dernier créneau à venir.
  int get _nombreSemaines {
    final futurs = widget.creneaux
        .where((c) => c.debut.isAfter(DateTime.now()))
        .map((c) => c.jour);
    if (futurs.isEmpty) return 1;
    final dernier = futurs.reduce((a, b) => a.isAfter(b) ? a : b);
    final semaines = (_lundiDe(dernier).difference(_premierLundi).inDays / 7)
        .round();
    return (semaines + 1).clamp(1, _semainesMax);
  }

  void _allerSemaine(int index) {
    _pages.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final semaines = _nombreSemaines;
    final lundi = _premierLundi.add(Duration(days: 7 * _semaine));
    final creneauxDuJour =
        widget.creneaux.where((c) => c.jour == _jour).toList()
          ..sort((a, b) => a.debut.compareTo(b.debut));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Guide(texte: widget.guide, couleur: widget.primaryColor),
        AppSpacing.vGap16,
        Row(
          children: [
            Expanded(
              child: Text(
                toBeginningOfSentenceCase(DateFormat.yMMMM().format(lundi)),
                style: AppTypography.texteSemiBold.copyWith(
                  fontSize: 16,
                  color: scheme.onSurface,
                ),
              ),
            ),
            IconButton(
              tooltip: tr('Semaine précédente'),
              onPressed: _semaine > 0
                  ? () => _allerSemaine(_semaine - 1)
                  : null,
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            IconButton(
              tooltip: tr('Semaine suivante'),
              onPressed: _semaine < semaines - 1
                  ? () => _allerSemaine(_semaine + 1)
                  : null,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
        SizedBox(
          height: 78,
          child: PageView.builder(
            controller: _pages,
            itemCount: semaines,
            onPageChanged: (index) => setState(() => _semaine = index),
            itemBuilder: (context, index) {
              final debut = _premierLundi.add(Duration(days: 7 * index));
              return Row(
                children: [
                  for (var i = 0; i < 7; i++)
                    Expanded(
                      child: _JourCell(
                        jour: debut.add(Duration(days: i)),
                        actif: debut.add(Duration(days: i)) == _jour,
                        libres: widget.creneaux
                            .where(
                              (c) =>
                                  c.jour == debut.add(Duration(days: i)) &&
                                  _estLibre(c),
                            )
                            .length,
                        couleur: widget.primaryColor,
                        onTap: (jour) => setState(() => _jour = jour),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        AppSpacing.vGap16,
        Text(
          toBeginningOfSentenceCase(DateFormat.MMMMEEEEd().format(_jour)),
          style: AppTypography.texteSemiBold.copyWith(color: scheme.onSurface),
        ),
        AppSpacing.vGap12,
        if (creneauxDuJour.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              tr(
                'Aucun créneau ce jour-là. Choisissez une date marquée d’un point.',
              ),
              style: AppTypography.texteSecondaire.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          )
        else
          for (final moment in _Moment.values)
            if (creneauxDuJour.any(moment.contient))
              _GroupeCreneaux(
                moment: moment,
                creneaux: creneauxDuJour.where(moment.contient).toList(),
                estLibre: _estLibre,
                selected: widget.selected,
                couleur: widget.primaryColor,
                onSelected: widget.onSelected,
              ),
        AppSpacing.vGap12,
        _Legende(couleur: widget.primaryColor),
      ],
    );
  }
}

class _Guide extends StatelessWidget {
  final String texte;
  final Color couleur;

  const _Guide({required this.texte, required this.couleur});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.touch_app_outlined, size: 20, color: couleur),
          AppSpacing.hGap12,
          Expanded(
            child: Text(
              texte,
              style: AppTypography.texte.copyWith(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JourCell extends StatelessWidget {
  final DateTime jour;
  final bool actif;
  final int libres;
  final Color couleur;
  final ValueChanged<DateTime> onTap;

  const _JourCell({
    required this.jour,
    required this.actif,
    required this.libres,
    required this.couleur,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final passe = jour.isBefore(_jourDe(DateTime.now()));
    final texte = actif
        ? Colors.white
        : (passe ? scheme.onSurface.withValues(alpha: 0.35) : scheme.onSurface);

    return Semantics(
      button: true,
      selected: actif,
      label:
          '${DateFormat.MMMMEEEEd().format(jour)}, '
          '${libres == 0 ? tr('aucun créneau libre') : tr('{n} créneau(x) libre(s)', {'n': libres})}',
      child: InkWell(
        onTap: passe ? null : () => onTap(jour),
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: actif ? couleur : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                toBeginningOfSentenceCase(
                  DateFormat.E().format(jour).replaceAll('.', ''),
                ),
                style: AppTypography.miniTexte.copyWith(
                  color: actif ? Colors.white70 : scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${jour.day}',
                style: AppTypography.texteSemiBold.copyWith(
                  fontSize: 17,
                  color: texte,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: libres > 0 && !passe
                      ? (actif ? Colors.white : const Color(0xFF2E9D63))
                      : Colors.transparent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Moments de la journée pour regrouper les créneaux.
enum _Moment {
  matin('Matin', Icons.wb_sunny_outlined),
  apresMidi('Après-midi', Icons.wb_cloudy_outlined),
  soir('Soir', Icons.nights_stay_outlined);

  final String label;
  final IconData icone;

  const _Moment(this.label, this.icone);

  bool contient(Creneau c) => switch (this) {
    _Moment.matin => c.debut.hour < 12,
    _Moment.apresMidi => c.debut.hour >= 12 && c.debut.hour < 18,
    _Moment.soir => c.debut.hour >= 18,
  };
}

class _GroupeCreneaux extends StatelessWidget {
  final _Moment moment;
  final List<Creneau> creneaux;
  final bool Function(Creneau) estLibre;
  final Creneau? selected;
  final Color couleur;
  final ValueChanged<Creneau>? onSelected;

  const _GroupeCreneaux({
    required this.moment,
    required this.creneaux,
    required this.estLibre,
    required this.selected,
    required this.couleur,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(moment.icone, size: 16, color: scheme.onSurfaceVariant),
              AppSpacing.hGap8,
              Text(
                tr(moment.label),
                style: AppTypography.miniTexte.copyWith(
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          AppSpacing.vGap8,
          LayoutBuilder(
            builder: (context, constraints) {
              // Quatre créneaux par ligne.
              final largeur = (constraints.maxWidth - 3 * 8) / 4;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in creneaux)
                    SizedBox(
                      width: largeur,
                      child: _CreneauChip(
                        creneau: c,
                        etat: !estLibre(c)
                            ? _EtatCreneau.indisponible
                            : (selected?.id == c.id
                                  ? _EtatCreneau.selectionne
                                  : _EtatCreneau.disponible),
                        couleur: couleur,
                        onTap: onSelected,
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

enum _EtatCreneau { disponible, selectionne, indisponible }

class _CreneauChip extends StatelessWidget {
  final Creneau creneau;
  final _EtatCreneau etat;
  final Color couleur;
  final ValueChanged<Creneau>? onTap;

  const _CreneauChip({
    required this.creneau,
    required this.etat,
    required this.couleur,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final heure = Formatters.formatHeure(creneau.debut);
    final (fond, bordure, texte) = switch (etat) {
      _EtatCreneau.selectionne => (couleur, couleur, Colors.white),
      _EtatCreneau.disponible => (
        scheme.surface,
        couleur.withValues(alpha: 0.45),
        couleur,
      ),
      _EtatCreneau.indisponible => (
        context.palette.muted,
        context.palette.border,
        context.palette.textSubtle,
      ),
    };
    final cliquable = etat != _EtatCreneau.indisponible && onTap != null;

    return Semantics(
      button: cliquable,
      selected: etat == _EtatCreneau.selectionne,
      label:
          '$heure, ${etat == _EtatCreneau.indisponible ? tr('indisponible') : tr('disponible')}',
      child: InkWell(
        onTap: cliquable ? () => onTap!(creneau) : null,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: fond,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: bordure, width: 1.2),
          ),
          child: Text(
            heure,
            style: AppTypography.texteSemiBold.copyWith(
              fontSize: 14,
              color: texte,
              decoration: etat == _EtatCreneau.indisponible
                  ? TextDecoration.lineThrough
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _Legende extends StatelessWidget {
  final Color couleur;

  const _Legende({required this.couleur});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget pastille(Color fond, Color bordure, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: fond,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: bordure, width: 1.2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTypography.miniTexte.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        pastille(scheme.surface, couleur.withValues(alpha: 0.45), 'Disponible'),
        pastille(couleur, couleur, tr('Sélectionné')),
        pastille(context.palette.muted, context.palette.border, 'Indisponible'),
      ],
    );
  }
}
