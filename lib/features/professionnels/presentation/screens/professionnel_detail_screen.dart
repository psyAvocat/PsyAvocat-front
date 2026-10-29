import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/user_message.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/universe_provider.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/image_media.dart';
import '../../../../shared/enums/slot_status.dart';
import '../../../dossiers/presentation/controllers/create_dossier_wizard_controller.dart';
import '../../../dossiers/presentation/controllers/dossiers_controller.dart';
import '../../../dossiers/presentation/screens/create_dossier_wizard_screen.dart';
import '../../../messagerie/data/repositories/messagerie_repository.dart';
import '../../../rendez_vous/data/models/reservation_contexte.dart';
import '../../../signalements/presentation/signalement_sheet.dart';
import '../../data/models/creneau.dart';
import '../../data/models/professionnel_detail.dart';
import '../controllers/professionnels_controller.dart';
import '../widgets/availability_picker.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_back_button.dart';

/// Fiche détaillée d'un professionnel : uniquement des données réelles du backend.
///
/// - Psychologue : choix d'un tarif publié puis réservation directe d'un créneau.
/// - Avocat : soumission d'un dossier ; une fois le dossier accepté par cet
///   avocat, « Prendre rendez-vous » réserve directement pour ce dossier.
/// Un professionnel d'un autre univers n'est jamais affiché (cloisonnement).
class ProfessionnelDetailScreen extends ConsumerStatefulWidget {
  final String professionnelId;

  const ProfessionnelDetailScreen({super.key, required this.professionnelId});

  @override
  ConsumerState<ProfessionnelDetailScreen> createState() =>
      _ProfessionnelDetailScreenState();
}

class _ProfessionnelDetailScreenState
    extends ConsumerState<ProfessionnelDetailScreen> {
  Tarif? _tarif;

  @override
  Widget build(BuildContext context) {
    final universe = ref.watch(currentUniverseProvider);
    final primaryColor = Theme.of(context).colorScheme.primary;
    final proAsync = ref.watch(
      professionnelDetailProvider(widget.professionnelId),
    );

    return proAsync.when(
      loading: () => Scaffold(
        backgroundColor: context.palette.page,
        appBar: AppBar(
          leading: const AppBackButton(),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: AppLoadingView(universe: universe),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: context.palette.page,
        appBar: AppBar(
          leading: const AppBackButton(),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: AppErrorStateView(
          title: tr('Professionnel indisponible'),
          message: userMessageFor(e),
          onRetry: () => ref.invalidate(
            professionnelDetailProvider(widget.professionnelId),
          ),
        ),
      ),
      data: (pro) {
        // Cloisonnement des univers : un avocat n'est jamais consultable depuis
        // l'univers Psychologue (lien profond, notification…), et inversement.
        if (pro.summary.type != universe.apiProfessionalType) {
          return Scaffold(
            backgroundColor: context.palette.page,
            appBar: AppBar(
              leading: const AppBackButton(),
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            body: AppEmptyStateView(
              icon: Icons.swap_horiz_rounded,
              title: tr('Professionnel d’un autre univers'),
              message: pro.summary.isAvocat
                  ? tr(
                      'Cette fiche appartient à l’univers Avocat. Changez d’univers pour la consulter.',
                    )
                  : tr(
                      'Cette fiche appartient à l’univers Psychologue. Changez d’univers pour la consulter.',
                    ),
            ),
          );
        }
        return _buildFiche(context, pro, primaryColor);
      },
    );
  }

  Widget _buildFiche(
    BuildContext context,
    ProfessionnelDetail pro,
    Color primaryColor,
  ) {
    final tarifs = pro.tarifs;
    final tarifChoisi = _tarif != null && tarifs.any((t) => t.id == _tarif!.id)
        ? _tarif
        : (tarifs.length == 1 ? tarifs.first : null);
    final photo = pro.summary.photoUrl;
    // Avocat : dossiers du justiciable qu'il a acceptés (rendez-vous possible).
    final prises = pro.summary.isAvocat
        ? (ref.watch(prisesEnChargeAvocatProvider(pro.id)).value ??
              const <PriseEnCharge>[])
        : const <PriseEnCharge>[];

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: context.palette.page,
        body: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverAppBar(
              expandedHeight: _hauteurPhoto,
              pinned: true,
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              leading: const AppBackButton(color: Colors.white),
              actions: [
                PopupMenuButton<String>(
                  tooltip: '',
                  icon: const Icon(Icons.more_vert_rounded),
                  onSelected: (action) {
                    if (action == 'signaler') {
                      _signaler(context, pro, primaryColor);
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'signaler',
                      child: ListTile(
                        leading: Icon(Icons.flag_outlined),
                        title: Text(tr('Signaler ce professionnel')),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
              flexibleSpace: _EnTeteFiche(
                pro: pro,
                hauteurDepliee: _hauteurPhoto,
                fond: FlexibleSpaceBar(
                  background: ImageMedia(
                    url: photo,
                    substitut: _PhotoParDefaut(pro: pro, color: primaryColor),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _Identite(pro: pro, primaryColor: primaryColor),
            ),
            if (prises.isNotEmpty)
              SliverToBoxAdapter(
                child: _BandeauPriseEnCharge(
                  prises: prises,
                  onSoumettreAutre: () => _soumettreDossier(context, pro),
                ),
              ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _OngletsDelegate(primaryColor: primaryColor),
            ),
          ],
          body: TabBarView(
            children: [
              _Presentation(pro: pro),
              _Tarifs(
                pro: pro,
                primaryColor: primaryColor,
                choisi: tarifChoisi,
                onChoisir: (t) => setState(() => _tarif = t),
              ),
              _Disponibilites(
                professionnelId: pro.id,
                primaryColor: primaryColor,
                avocat: pro.summary.isAvocat,
                dossierAccepte: prises.isNotEmpty,
                onCreneau: (c) => _reserverCreneau(
                  context,
                  pro,
                  tarifChoisi,
                  c,
                  primaryColor,
                  prises,
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _BarreAction(
          pro: pro,
          primaryColor: primaryColor,
          tarif: tarifChoisi,
          dossierAccepte: prises.isNotEmpty,
          onReserverDossier: () =>
              _reserverDossier(context, prises, null, primaryColor),
          onEcrire: () => _ecrire(context, pro),
        ),
      ),
    );
  }

  Future<void> _signaler(
    BuildContext context,
    ProfessionnelDetail pro,
    Color primaryColor,
  ) async {
    final envoye = await showSignalementSheet(
      context,
      professionnelId: pro.id,
      professionnelNom: pro.summary.displayName,
      primaryColor: primaryColor,
    );
    if (envoye == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr('Signalement envoyé. L’équipe PsyAvocat va l’examiner.'),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Créneau vert touché dans l'onglet Disponibilités : la réservation démarre
  /// avec ce créneau présélectionné (tarif demandé s'il y en a plusieurs).
  /// Chez un avocat, le rendez-vous se prend après acceptation d'un dossier :
  /// réservation directe si un dossier est accepté, sinon invitation à en soumettre un.
  Future<void> _reserverCreneau(
    BuildContext context,
    ProfessionnelDetail pro,
    Tarif? tarifChoisi,
    Creneau creneau,
    Color primaryColor,
    List<PriseEnCharge> prises,
  ) async {
    if (pro.summary.isAvocat && prises.isNotEmpty) {
      await _reserverDossier(context, prises, creneau, primaryColor);
      return;
    }
    if (pro.summary.isAvocat) {
      final soumettre = await showModalBottomSheet<bool>(
        context: context,
        showDragHandle: true,
        builder: (_) => _InfoDossierSheet(
          nom: pro.summary.displayName,
          primaryColor: primaryColor,
        ),
      );
      if (soumettre == true && context.mounted) {
        _soumettreDossier(context, pro);
      }
      return;
    }
    if (pro.tarifs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              'Ce professionnel n’a pas encore publié de tarif : la réservation n’est pas encore possible.',
            ),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final tarif =
        tarifChoisi ??
        await showModalBottomSheet<Tarif>(
          context: context,
          showDragHandle: true,
          isScrollControlled: true,
          builder: (_) =>
              _ChoixTarifSheet(tarifs: pro.tarifs, primaryColor: primaryColor),
        );
    if (tarif == null || !context.mounted) return;
    setState(() => _tarif = tarif);
    context.push(
      AppRoutes.choixCreneau(pro.id),
      extra: ReservationContexte.psychologue(
        professionnelId: pro.id,
        tarif: tarif,
        creneauPropose: creneau,
      ),
    );
  }

  /// Rendez-vous pour un dossier accepté par cet avocat (choix du dossier s'il
  /// en a accepté plusieurs) ; le montant est celui des honoraires proposés.
  Future<void> _reserverDossier(
    BuildContext context,
    List<PriseEnCharge> prises,
    Creneau? creneau,
    Color primaryColor,
  ) async {
    if (prises.isEmpty) return;
    final prise = prises.length == 1
        ? prises.first
        : await showModalBottomSheet<PriseEnCharge>(
            context: context,
            showDragHandle: true,
            builder: (_) =>
                _ChoixDossierSheet(prises: prises, primaryColor: primaryColor),
          );
    if (prise == null || !context.mounted) return;
    context.push(
      AppRoutes.choixCreneau(prise.soumission.avocatId),
      extra: ReservationContexte.avocat(
        professionnelId: prise.soumission.avocatId,
        soumissionId: prise.soumission.id,
        dossierTitre: prise.dossier.titre,
        montantDossier: prise.soumission.tarifPropose!,
        creneauPropose: creneau,
      ),
    );
  }

  void _soumettreDossier(BuildContext context, ProfessionnelDetail pro) {
    ref.read(createDossierWizardProvider.notifier).preselectionner(pro.summary);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreateDossierWizardScreen()),
    );
  }

  /// Ouvre directement la discussion avec le professionnel : l'existante, sinon
  /// un brouillon qui ne sera créé qu'à l'envoi du premier message (rien ne
  /// reste si le client repart sans écrire).
  Future<void> _ecrire(BuildContext context, ProfessionnelDetail pro) async {
    try {
      final conversation = await ref
          .read(messagerieRepositoryProvider)
          .ouvrirAvec(pro.id);
      if (!context.mounted) return;
      context.push(
        conversation.id.isEmpty
            ? AppRoutes.nouvelleConversation(pro.id)
            : AppRoutes.conversation(conversation.id),
        extra: {
          'name': pro.summary.displayName,
          'role': pro.summary.type,
          'photoUrl': pro.summary.photoUrl,
        },
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userMessageFor(error)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

/// Hauteur de la photo en tête de fiche.
const _hauteurPhoto = 240.0;

/// En-tête de la fiche : la photo, puis, une fois la photo repliée en faisant
/// défiler, la miniature et le nom du professionnel dans la barre du haut
/// (au lieu d'un bandeau de couleur vide).
class _EnTeteFiche extends StatelessWidget {
  final ProfessionnelDetail pro;
  final double hauteurDepliee;
  final Widget fond;

  const _EnTeteFiche({
    required this.pro,
    required this.hauteurDepliee,
    required this.fond,
  });

  @override
  Widget build(BuildContext context) {
    final haut = MediaQuery.paddingOf(context).top;
    final hauteurRepliee = kToolbarHeight + haut;
    return LayoutBuilder(
      builder: (context, contraintes) {
        // 1 : photo entièrement visible ; 0 : barre repliée.
        final deplie =
            ((contraintes.maxHeight - hauteurRepliee) /
                    (hauteurDepliee + haut - hauteurRepliee))
                .clamp(0.0, 1.0);
        // Le nom apparaît progressivement sur le dernier quart du repli.
        final opacite = ((0.25 - deplie) / 0.25).clamp(0.0, 1.0);
        return Stack(
          fit: StackFit.expand,
          children: [
            fond,
            Positioned(
              left: 56,
              right: 56,
              top: haut,
              height: kToolbarHeight,
              child: IgnorePointer(
                child: Opacity(
                  opacity: opacite,
                  child: Row(
                    children: [
                      AppAvatar(
                        name: pro.summary.displayName,
                        photoUrl: pro.summary.photoUrl,
                        size: 34,
                      ),
                      AppSpacing.hGap12,
                      Expanded(
                        child: Text(
                          pro.summary.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.texteSemiBold.copyWith(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PhotoParDefaut extends StatelessWidget {
  final ProfessionnelDetail pro;
  final Color color;
  const _PhotoParDefaut({required this.pro, required this.color});

  /// Sans photo : silhouette de profil dans un cercle clair, sur un dégradé
  /// doux de la couleur de l'univers (plutôt qu'un pictogramme de métier).
  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: tr('Photo de {nom}', {'nom': pro.summary.displayName}),
      image: true,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, Color.lerp(color, Colors.white, 0.28)!],
          ),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.only(top: 24),
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.18),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.55),
              width: 2,
            ),
          ),
          child: Icon(
            Icons.person_rounded,
            size: 76,
            color: Colors.white.withValues(alpha: 0.95),
          ),
        ),
      ),
    );
  }
}

class _Identite extends StatelessWidget {
  final ProfessionnelDetail pro;
  final Color primaryColor;
  const _Identite({required this.pro, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    final s = pro.summary;
    final mode = s.modeConsultationLabel;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.displayName,
            style: AppTypography.titreMoyen.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: context.palette.textStrong,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (s.hasRating)
                _Info(
                  icone: Icons.star_rounded,
                  couleur: const Color(0xFFF59E0B),
                  texte: tr('{note} ({n} avis)', {
                    'note': s.noteMoyenne!.toStringAsFixed(1),
                    'n': s.nombreAvis,
                  }),
                ),
              if (s.ville != null && s.ville!.isNotEmpty)
                _Info(icone: Icons.location_on_outlined, texte: s.ville!),
              if (mode != null)
                _Info(icone: Icons.video_call_outlined, texte: mode),
            ],
          ),
          if (pro.specialites.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: pro.specialites
                  .map(
                    (sp) => Chip(
                      label: Text(sp.nom),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                      backgroundColor: primaryColor.withValues(alpha: 0.08),
                      side: BorderSide(
                        color: primaryColor.withValues(alpha: 0.2),
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 16),
          AppButton.outline(
            text: s.isAvocat
                ? tr('Voir les articles')
                : tr('Voir les conseils'),
            icon: s.isAvocat
                ? Icons.menu_book_outlined
                : Icons.lightbulb_outline_rounded,
            color: primaryColor,
            onPressed: () => context.push(
              AppRoutes.publicationsProfessionnel(pro.id),
              extra: s.displayName,
            ),
          ),
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  final IconData icone;
  final String texte;
  final Color? couleur;
  const _Info({required this.icone, required this.texte, this.couleur});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icone, size: 16, color: couleur ?? context.palette.textSubtle),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            texte,
            style: TextStyle(fontSize: 13, color: context.palette.text),
          ),
        ),
      ],
    );
  }
}

class _OngletsDelegate extends SliverPersistentHeaderDelegate {
  final Color primaryColor;
  _OngletsDelegate({required this.primaryColor});

  @override
  double get minExtent => 52;
  @override
  double get maxExtent => 52;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: context.palette.page,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: context.palette.muted,
          borderRadius: BorderRadius.circular(22),
        ),
        child: TabBar(
          indicator: BoxDecoration(
            color: context.palette.card,
            borderRadius: BorderRadius.circular(22),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: context.palette.textStrong,
          unselectedLabelColor: context.palette.textMuted,
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          tabs: [
            Tab(text: tr('Présentation')),
            Tab(text: tr('Tarifs')),
            Tab(text: tr('Disponibilités')),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _OngletsDelegate oldDelegate) =>
      oldDelegate.primaryColor != primaryColor;
}

class _Presentation extends StatelessWidget {
  final ProfessionnelDetail pro;
  const _Presentation({required this.pro});

  @override
  Widget build(BuildContext context) {
    final bio = pro.biographie?.trim() ?? '';
    final langues = (pro.langues ?? '')
        .split(',')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _Section(tr('À propos')),
        Text(
          bio.isNotEmpty
              ? bio
              : tr('Ce professionnel n’a pas encore rédigé de présentation.'),
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: bio.isNotEmpty
                ? context.palette.text
                : context.palette.textSubtle,
          ),
        ),
        if (pro.adresse != null && pro.adresse!.isNotEmpty) ...[
          const SizedBox(height: 20),
          _Section(tr('Adresse du cabinet')),
          Text(
            pro.adresse!,
            style: TextStyle(fontSize: 14, color: context.palette.text),
          ),
        ],
        if (langues.isNotEmpty) ...[
          const SizedBox(height: 20),
          const _Section('Langues'),
          Wrap(
            spacing: 8,
            children: langues.map((l) => Chip(label: Text(l))).toList(),
          ),
        ],
      ],
    );
  }
}

class _Tarifs extends StatelessWidget {
  final ProfessionnelDetail pro;
  final Color primaryColor;
  final Tarif? choisi;
  final ValueChanged<Tarif> onChoisir;
  const _Tarifs({
    required this.pro,
    required this.primaryColor,
    required this.choisi,
    required this.onChoisir,
  });

  @override
  Widget build(BuildContext context) {
    if (pro.summary.isAvocat && pro.tarifs.isEmpty) {
      return AppEmptyStateView(
        icon: Icons.folder_shared_outlined,
        title: tr('Honoraires sur dossier'),
        message: tr(
          'L’avocat vous communique ses honoraires lorsqu’il accepte votre dossier.',
        ),
      );
    }
    if (pro.tarifs.isEmpty) {
      return AppEmptyStateView(
        icon: Icons.sell_outlined,
        title: tr('Aucun tarif publié'),
        message: tr(
          'Ce professionnel n’a pas encore publié de tarif : la réservation n’est pas encore possible.',
        ),
      );
    }
    final avocat = pro.summary.isAvocat;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (avocat)
          Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              tr(
                'Tarifs indicatifs. Les honoraires définitifs vous sont proposés lorsque l’avocat accepte votre dossier.',
              ),
              style: TextStyle(
                fontSize: 13,
                color: context.palette.textMuted,
                height: 1.4,
              ),
            ),
          ),
        ...pro.tarifs.map((t) {
          final actif = !avocat && choisi?.id == t.id;
          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: actif ? primaryColor : context.palette.border,
                width: actif ? 1.6 : 1,
              ),
            ),
            child: ListTile(
              onTap: avocat ? null : () => onChoisir(t),
              title: Text(
                t.titre,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: t.description != null || t.dureeMinutes != null
                  ? Text(
                      [
                        if (t.dureeMinutes != null) '${t.dureeMinutes} min',
                        if (t.description != null) t.description!,
                      ].join(' • '),
                    )
                  : null,
              trailing: Text(
                Formatters.formatFcfa(t.montant),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: primaryColor,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _Disponibilites extends ConsumerWidget {
  final String professionnelId;
  final Color primaryColor;
  final bool avocat;

  /// Avocat ayant accepté un dossier du justiciable : les créneaux se réservent.
  final bool dossierAccepte;
  final ValueChanged<Creneau> onCreneau;
  const _Disponibilites({
    required this.professionnelId,
    required this.primaryColor,
    required this.avocat,
    required this.onCreneau,
    this.dossierAccepte = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final creneauxAsync = ref.watch(creneauxProvider(professionnelId));
    return creneauxAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => AppErrorStateView(
        message: userMessageFor(e),
        onRetry: () => ref.invalidate(creneauxProvider(professionnelId)),
      ),
      data: (creneaux) {
        final maintenant = DateTime.now();
        final libres = creneaux
            .where(
              (c) =>
                  c.statut == SlotStatus.libre && c.debut.isAfter(maintenant),
            )
            .toList();
        if (libres.isEmpty) {
          return AppEmptyStateView(
            icon: Icons.event_busy_rounded,
            title: tr('Aucun créneau disponible'),
            message: tr(
              'Les nouvelles disponibilités apparaîtront ici automatiquement.',
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            AvailabilityPicker(
              creneaux: creneaux,
              primaryColor: primaryColor,
              onSelected: onCreneau,
              guide: avocat && !dossierAccepte
                  ? tr(
                      'Parcourez les disponibilités. Le rendez-vous se réserve '
                      'une fois votre dossier accepté par l’avocat.',
                    )
                  : tr(
                      'Choisissez une date marquée d’un point vert, puis touchez '
                      'un créneau vert pour le réserver.',
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _Section extends StatelessWidget {
  final String titre;
  const _Section(this.titre);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        titre,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: context.palette.textStrong,
        ),
      ),
    );
  }
}

class _BarreAction extends ConsumerWidget {
  final ProfessionnelDetail pro;
  final Color primaryColor;
  final Tarif? tarif;
  final VoidCallback onEcrire;

  /// Avocat : un dossier du justiciable est accepté, le rendez-vous se prend.
  final bool dossierAccepte;
  final VoidCallback onReserverDossier;

  const _BarreAction({
    required this.pro,
    required this.primaryColor,
    required this.tarif,
    required this.onEcrire,
    required this.dossierAccepte,
    required this.onReserverDossier,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avocat = pro.summary.isAvocat;
    final VoidCallback? action;
    final String libelle;
    if (avocat && dossierAccepte) {
      libelle = tr('Prendre rendez-vous');
      action = onReserverDossier;
    } else if (avocat) {
      libelle = tr('Soumettre un dossier');
      action = () {
        ref
            .read(createDossierWizardProvider.notifier)
            .preselectionner(pro.summary);
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CreateDossierWizardScreen()),
        );
      };
    } else {
      libelle = tarif != null
          ? tr('Prendre rendez-vous')
          : (pro.tarifs.isEmpty
                ? tr('Réservation indisponible')
                : tr('Choisissez un tarif'));
      action = tarif == null
          ? null
          : () {
              context.push(
                AppRoutes.choixCreneau(pro.id),
                extra: ReservationContexte.psychologue(
                  professionnelId: pro.id,
                  tarif: tarif!,
                ),
              );
            };
    }

    return Container(
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
        child: Row(
          children: [
            IconButton.outlined(
              onPressed: onEcrire,
              tooltip: tr('Écrire'),
              icon: Icon(
                Icons.chat_bubble_outline_rounded,
                color: primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppButton(
                text: libelle,
                onPressed: action,
                color: primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Choix du tarif (psychologue) avant de réserver le créneau touché.
class _ChoixTarifSheet extends StatelessWidget {
  final List<Tarif> tarifs;
  final Color primaryColor;

  const _ChoixTarifSheet({required this.tarifs, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              tr('Choisissez une consultation'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.palette.textStrong,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              tr('Le prix est celui publié par le professionnel.'),
              style: TextStyle(fontSize: 13, color: context.palette.textMuted),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final t in tarifs)
                    Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: context.palette.border),
                      ),
                      child: ListTile(
                        onTap: () => Navigator.pop(context, t),
                        title: Text(
                          t.titre,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: t.dureeMinutes != null
                            ? Text('${t.dureeMinutes} min')
                            : null,
                        trailing: Text(
                          Formatters.formatFcfa(t.montant),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dossier(s) accepté(s) par cet avocat : rappel en tête de fiche.
class _BandeauPriseEnCharge extends StatelessWidget {
  final List<PriseEnCharge> prises;
  final VoidCallback onSoumettreAutre;

  const _BandeauPriseEnCharge({
    required this.prises,
    required this.onSoumettreAutre,
  });

  @override
  Widget build(BuildContext context) {
    final couleur = Theme.of(context).colorScheme.primary;
    final premiere = prises.first;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Material(
        color: couleur.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: couleur.withValues(alpha: 0.2)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () =>
              context.push(AppRoutes.dossierPriseEnCharge(premiere.dossier.id)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.verified_outlined, color: couleur, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        prises.length == 1
                            ? tr(
                                'Votre dossier « {titre} » est pris en charge par cet avocat.',
                                {'titre': premiere.dossier.titre},
                              )
                            : tr(
                                '{n} de vos dossiers sont pris en charge par cet avocat.',
                                {'n': prises.length},
                              ),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: context.palette.textStrong,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: couleur),
                  ],
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: onSoumettreAutre,
                    style: TextButton.styleFrom(
                      foregroundColor: couleur,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(tr('Soumettre un autre dossier')),
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

/// Plusieurs dossiers acceptés par cet avocat : choix du dossier du rendez-vous.
class _ChoixDossierSheet extends StatelessWidget {
  final List<PriseEnCharge> prises;
  final Color primaryColor;

  const _ChoixDossierSheet({required this.prises, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              tr('Pour quel dossier ?'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.palette.textStrong,
              ),
            ),
            const SizedBox(height: 12),
            for (final prise in prises)
              Card(
                elevation: 0,
                color: context.palette.muted,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Icon(Icons.folder_outlined, color: primaryColor),
                  title: Text(
                    prise.dossier.titre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    tr('Honoraires proposés : {montant}', {
                      'montant': Formatters.formatFcfa(
                        prise.soumission.tarifPropose!,
                      ),
                    }),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.pop(context, prise),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Chez un avocat, le créneau se réserve après acceptation d'un dossier.
class _InfoDossierSheet extends StatelessWidget {
  final String nom;
  final Color primaryColor;

  const _InfoDossierSheet({required this.nom, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.folder_shared_outlined, size: 40, color: primaryColor),
            const SizedBox(height: 12),
            Text(
              tr('Un dossier d’abord'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.palette.textStrong,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tr(
                'Soumettez votre dossier à {nom}. Dès qu’il l’accepte, vous '
                'choisissez l’un de ces créneaux pour votre rendez-vous.',
                {'nom': nom},
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: context.palette.textMuted,
              ),
            ),
            const SizedBox(height: 20),
            AppButton(
              text: tr('Soumettre un dossier'),
              color: primaryColor,
              onPressed: () => Navigator.pop(context, true),
            ),
            const SizedBox(height: 8),
            AppButton.ghost(
              text: tr('Plus tard'),
              onPressed: () => Navigator.pop(context, false),
            ),
          ],
        ),
      ),
    );
  }
}
