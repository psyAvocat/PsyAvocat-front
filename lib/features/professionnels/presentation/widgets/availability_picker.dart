import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/enums/slot_status.dart';
import '../../data/models/creneau.dart';
import '../../../../core/l10n/app_strings.dart';

/// Sélecteur de disponibilités en deux vues :
/// - Semaine : une semaine à la fois (flèches ou glissement) ;
/// - Mois : le mois entier d'un coup d'œil, utile quand le professionnel a
///   planifié tout son mois.
/// Une pastille verte marque chaque jour qui a des créneaux libres ; les créneaux
/// du jour choisi s'affichent dessous, regroupés par moment de la journée.
///
/// Les créneaux disponibles sont en vert, le créneau sélectionné en vert plein,
/// les créneaux indisponibles (réservés, bloqués ou passés) grisés et barrés.
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

/// Horizon proposé à partir de la semaine courante (environ six mois).
const _semainesMax = 26;
const _moisMax = 6;

DateTime _jourDe(DateTime d) => DateTime(d.year, d.month, d.day);

/// Lundi de la semaine qui contient [d].
DateTime _lundiDe(DateTime d) =>
    _jourDe(d).subtract(Duration(days: d.weekday - 1));

DateTime _moisDe(DateTime d) => DateTime(d.year, d.month);

/// Couleurs des créneaux disponibles : une variante de vert lisible en mode
/// clair comme en mode sombre.
class _Vert {
  final Color plein;
  final Color fond;
  final Color bordure;
  final Color texte;

  const _Vert._(this.plein, this.fond, this.bordure, this.texte);

  factory _Vert.de(BuildContext context) {
    final sombre = Theme.of(context).brightness == Brightness.dark;
    return sombre
        ? const _Vert._(
            Color(0xFF34B474),
            Color(0x2634B474),
            Color(0xFF3FB97A),
            Color(0xFF8BE0B2),
          )
        : const _Vert._(
            Color(0xFF2E9D63),
            Color(0xFFE9F7EF),
            Color(0xFF8ACFA9),
            Color(0xFF1C7A49),
          );
  }
}

class _AvailabilityPickerState extends State<AvailabilityPicker> {
  late final DateTime _premierLundi = _lundiDe(DateTime.now());
  late final DateTime _premierMois = _moisDe(DateTime.now());
  late PageController _pages;
  late DateTime _jour;
  late int _semaine;
  late DateTime _mois;
  bool _vueMois = false;

  @override
  void initState() {
    super.initState();
    _jour =
        widget.selected?.jour ?? _premierJourLibre() ?? _jourDe(DateTime.now());
    _semaine = _semaineDe(_jour);
    _mois = _moisDe(_jour);
    _pages = PageController(initialPage: _semaine);
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  bool _estLibre(Creneau c) =>
      c.statut == SlotStatus.libre && c.debut.isAfter(DateTime.now());

  int _libresLe(DateTime jour) =>
      widget.creneaux.where((c) => c.jour == jour && _estLibre(c)).length;

  DateTime? _premierJourLibre() {
    final libres = widget.creneaux.where(_estLibre).map((c) => c.jour).toList()
      ..sort();
    return libres.firstOrNull;
  }

  DateTime? get _dernierJourFutur {
    final futurs = widget.creneaux
        .where((c) => c.debut.isAfter(DateTime.now()))
        .map((c) => c.jour);
    if (futurs.isEmpty) return null;
    return futurs.reduce((a, b) => a.isAfter(b) ? a : b);
  }

  int _semaineDe(DateTime jour) =>
      (_lundiDe(jour).difference(_premierLundi).inDays / 7).round().clamp(
        0,
        _nombreSemaines - 1,
      );

  /// De la semaine courante jusqu'à celle du dernier créneau à venir.
  int get _nombreSemaines {
    final dernier = _dernierJourFutur;
    if (dernier == null) return 1;
    final semaines = (_lundiDe(dernier).difference(_premierLundi).inDays / 7)
        .round();
    return (semaines + 1).clamp(1, _semainesMax);
  }

  /// Du mois courant jusqu'à celui du dernier créneau à venir.
  int get _nombreMois {
    final dernier = _dernierJourFutur;
    if (dernier == null) return 1;
    final mois =
        (dernier.year - _premierMois.year) * 12 +
        dernier.month -
        _premierMois.month;
    return (mois + 1).clamp(1, _moisMax);
  }

  int get _indexMois =>
      (_mois.year - _premierMois.year) * 12 + _mois.month - _premierMois.month;

  void _allerSemaine(int index) {
    _pages.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _allerMois(int delta) {
    setState(() => _mois = DateTime(_mois.year, _mois.month + delta));
  }

  void _changerVue(bool mois) {
    if (mois == _vueMois) return;
    setState(() {
      _vueMois = mois;
      if (mois) {
        _mois = _moisDe(_jour);
      } else {
        // La vue semaine reprend sur la semaine du jour choisi dans le mois.
        _semaine = _semaineDe(_jour);
        final ancien = _pages;
        _pages = PageController(initialPage: _semaine);
        WidgetsBinding.instance.addPostFrameCallback((_) => ancien.dispose());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final vert = _Vert.de(context);
    final semaines = _nombreSemaines;
    final lundi = _premierLundi.add(Duration(days: 7 * _semaine));
    final titre = _vueMois ? _mois : lundi;
    final precedentActif = _vueMois ? _indexMois > 0 : _semaine > 0;
    final suivantActif = _vueMois
        ? _indexMois < _nombreMois - 1
        : _semaine < semaines - 1;
    final creneauxDuJour =
        widget.creneaux.where((c) => c.jour == _jour).toList()
          ..sort((a, b) => a.debut.compareTo(b.debut));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Guide(texte: widget.guide, couleur: widget.primaryColor),
        AppSpacing.vGap16,
        Align(
          alignment: Alignment.centerLeft,
          child: _ChoixVue(
            mois: _vueMois,
            couleur: widget.primaryColor,
            onChanged: _changerVue,
          ),
        ),
        AppSpacing.vGap8,
        Row(
          children: [
            Expanded(
              child: Text(
                toBeginningOfSentenceCase(DateFormat.yMMMM().format(titre)),
                style: AppTypography.texteSemiBold.copyWith(
                  fontSize: 16,
                  color: scheme.onSurface,
                ),
              ),
            ),
            IconButton(
              tooltip: _vueMois
                  ? tr('Mois précédent')
                  : tr('Semaine précédente'),
              onPressed: precedentActif
                  ? () =>
                        _vueMois ? _allerMois(-1) : _allerSemaine(_semaine - 1)
                  : null,
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            IconButton(
              tooltip: _vueMois ? tr('Mois suivant') : tr('Semaine suivante'),
              onPressed: suivantActif
                  ? () => _vueMois ? _allerMois(1) : _allerSemaine(_semaine + 1)
                  : null,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
        if (_vueMois)
          _GrilleMois(
            mois: _mois,
            jourActif: _jour,
            libresLe: _libresLe,
            couleur: widget.primaryColor,
            vert: vert,
            onTap: (jour) => setState(() => _jour = jour),
          )
        else
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
                          libres: _libresLe(debut.add(Duration(days: i))),
                          couleur: widget.primaryColor,
                          vert: vert,
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
                'Aucun créneau ce jour-là. Choisissez une date marquée d’un point vert.',
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
                vert: vert,
                onSelected: widget.onSelected,
              ),
        AppSpacing.vGap12,
        _Legende(vert: vert),
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

/// Bascule Semaine / Mois.
class _ChoixVue extends StatelessWidget {
  final bool mois;
  final Color couleur;
  final ValueChanged<bool> onChanged;

  const _ChoixVue({
    required this.mois,
    required this.couleur,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    Widget option(String label, bool valeur) {
      final actif = mois == valeur;
      return Semantics(
        button: true,
        selected: actif,
        child: InkWell(
          onTap: () => onChanged(valeur),
          borderRadius: BorderRadius.circular(9),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: actif ? palette.card : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
              boxShadow: actif
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              label,
              style: AppTypography.miniTexte.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: actif ? couleur : palette.textMuted,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: palette.muted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [option(tr('Semaine'), false), option(tr('Mois'), true)],
      ),
    );
  }
}

class _JourCell extends StatelessWidget {
  final DateTime jour;
  final bool actif;
  final int libres;
  final Color couleur;
  final _Vert vert;
  final ValueChanged<DateTime> onTap;

  const _JourCell({
    required this.jour,
    required this.actif,
    required this.libres,
    required this.couleur,
    required this.vert,
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
              _Point(visible: libres > 0 && !passe, actif: actif, vert: vert),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pastille verte d'un jour qui a des créneaux libres.
class _Point extends StatelessWidget {
  final bool visible;
  final bool actif;
  final _Vert vert;

  const _Point({
    required this.visible,
    required this.actif,
    required this.vert,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: visible
            ? (actif ? Colors.white : vert.plein)
            : Colors.transparent,
      ),
    );
  }
}

/// Mois entier : une ligne par semaine (lundi en premier).
class _GrilleMois extends StatelessWidget {
  final DateTime mois;
  final DateTime jourActif;
  final int Function(DateTime) libresLe;
  final Color couleur;
  final _Vert vert;
  final ValueChanged<DateTime> onTap;

  const _GrilleMois({
    required this.mois,
    required this.jourActif,
    required this.libresLe,
    required this.couleur,
    required this.vert,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final premier = DateTime(mois.year, mois.month);
    final nbJours = DateTime(mois.year, mois.month + 1, 0).day;
    final debut = _lundiDe(premier);
    final nbCases = ((premier.weekday - 1 + nbJours) / 7).ceil() * 7;
    final aujourdhui = _jourDe(DateTime.now());
    var libresDuMois = 0;
    for (var d = 1; d <= nbJours; d++) {
      libresDuMois += libresLe(DateTime(mois.year, mois.month, d));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Center(
                  child: Text(
                    toBeginningOfSentenceCase(
                      DateFormat.E()
                          .format(debut.add(Duration(days: i)))
                          .replaceAll('.', ''),
                    ),
                    style: AppTypography.miniTexte.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
          ],
        ),
        AppSpacing.vGap8,
        for (var ligne = 0; ligne < nbCases ~/ 7; ligne++)
          Row(
            children: [
              for (var col = 0; col < 7; col++)
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final jour = DateTime(
                        debut.year,
                        debut.month,
                        debut.day + ligne * 7 + col,
                      );
                      if (jour.month != mois.month) {
                        return const SizedBox(height: 46);
                      }
                      final libres = libresLe(jour);
                      final passe = jour.isBefore(aujourdhui);
                      final actif = jour == jourActif;
                      return Semantics(
                        button: true,
                        selected: actif,
                        label:
                            '${DateFormat.MMMMEEEEd().format(jour)}, '
                            '${libres == 0 ? tr('aucun créneau libre') : tr('{n} créneau(x) libre(s)', {'n': libres})}',
                        child: InkWell(
                          onTap: passe ? null : () => onTap(jour),
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            height: 46,
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: actif
                                  ? couleur
                                  : (libres > 0 && !passe
                                        ? vert.fond
                                        : Colors.transparent),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${jour.day}',
                                  style: AppTypography.texteSemiBold.copyWith(
                                    fontSize: 15,
                                    color: actif
                                        ? Colors.white
                                        : (passe
                                              ? scheme.onSurface.withValues(
                                                  alpha: 0.35,
                                                )
                                              : scheme.onSurface),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                _Point(
                                  visible: libres > 0 && !passe,
                                  actif: actif,
                                  vert: vert,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        AppSpacing.vGap8,
        Text(
          libresDuMois == 0
              ? tr('Aucun créneau libre ce mois-ci.')
              : tr('{n} créneau(x) libre(s) ce mois-ci', {'n': libresDuMois}),
          style: AppTypography.miniTexte.copyWith(
            fontWeight: FontWeight.w600,
            color: libresDuMois == 0 ? scheme.onSurfaceVariant : vert.texte,
          ),
        ),
      ],
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
  final _Vert vert;
  final ValueChanged<Creneau>? onSelected;

  const _GroupeCreneaux({
    required this.moment,
    required this.creneaux,
    required this.estLibre,
    required this.selected,
    required this.vert,
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
                        vert: vert,
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
  final _Vert vert;
  final ValueChanged<Creneau>? onTap;

  const _CreneauChip({
    required this.creneau,
    required this.etat,
    required this.vert,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final heure = Formatters.formatHeure(creneau.debut);
    final (fond, bordure, texte) = switch (etat) {
      _EtatCreneau.selectionne => (vert.plein, vert.plein, Colors.white),
      _EtatCreneau.disponible => (vert.fond, vert.bordure, vert.texte),
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
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (etat == _EtatCreneau.selectionne) ...[
                  const Icon(
                    Icons.check_rounded,
                    size: 15,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 3),
                ],
                Text(
                  heure,
                  style: AppTypography.texteSemiBold.copyWith(
                    fontSize: 14,
                    color: texte,
                    decoration: etat == _EtatCreneau.indisponible
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Legende extends StatelessWidget {
  final _Vert vert;

  const _Legende({required this.vert});

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
        pastille(vert.fond, vert.bordure, tr('Disponible')),
        pastille(vert.plein, vert.plein, tr('Sélectionné')),
        pastille(
          context.palette.muted,
          context.palette.border,
          tr('Indisponible'),
        ),
      ],
    );
  }
}
