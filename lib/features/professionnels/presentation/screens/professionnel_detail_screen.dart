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
import '../../../dossiers/presentation/controllers/create_dossier_wizard_controller.dart';
import '../../../dossiers/presentation/screens/create_dossier_wizard_screen.dart';
import '../../../messagerie/data/repositories/messagerie_repository.dart';
import '../../../rendez_vous/data/models/reservation_contexte.dart';
import '../../../signalements/presentation/signalement_sheet.dart';
import '../../data/models/creneau.dart';
import '../../data/models/professionnel_detail.dart';
import '../controllers/professionnels_controller.dart';

/// Fiche détaillée d'un professionnel : uniquement des données réelles du backend.
///
/// - Psychologue : choix d'un tarif publié puis réservation directe d'un créneau.
/// - Avocat : soumission d'un dossier (le rendez-vous se prend après acceptation).
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
    final primaryColor = universe.primaryColor;
    final proAsync = ref.watch(
      professionnelDetailProvider(widget.professionnelId),
    );

    return proAsync.when(
      loading: () => Scaffold(
        backgroundColor: const Color(0xFFF9FAFC),
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: AppLoadingView(universe: universe),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: const Color(0xFFF9FAFC),
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: AppErrorStateView(
          title: 'Professionnel indisponible',
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
            backgroundColor: const Color(0xFFF9FAFC),
            appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
            body: AppEmptyStateView(
              icon: Icons.swap_horiz_rounded,
              title: 'Professionnel d’un autre univers',
              message: pro.summary.isAvocat
                  ? 'Cette fiche appartient à l’univers Avocat. Changez d’univers pour la consulter.'
                  : 'Cette fiche appartient à l’univers Psychologue. Changez d’univers pour la consulter.',
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

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFC),
        body: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverAppBar(
              expandedHeight: 240,
              pinned: true,
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              actions: [
                PopupMenuButton<String>(
                  tooltip: 'Plus d’actions',
                  icon: const Icon(Icons.more_vert_rounded),
                  onSelected: (action) {
                    if (action == 'signaler')
                      _signaler(context, pro, primaryColor);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'signaler',
                      child: ListTile(
                        leading: Icon(Icons.flag_outlined),
                        title: Text('Signaler ce professionnel'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: photo != null
                    ? Image.network(
                        photo,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            _PhotoParDefaut(pro: pro, color: primaryColor),
                      )
                    : _PhotoParDefaut(pro: pro, color: primaryColor),
              ),
            ),
            SliverToBoxAdapter(
              child: _Identite(pro: pro, primaryColor: primaryColor),
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
              ),
            ],
          ),
        ),
        bottomNavigationBar: _BarreAction(
          pro: pro,
          primaryColor: primaryColor,
          tarif: tarifChoisi,
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
        const SnackBar(
          content: Text(
            'Signalement envoyé. L’équipe PsyAvocat va l’examiner.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Premier message : la conversation est créée (ou réutilisée) par le backend.
  Future<void> _ecrire(BuildContext context, ProfessionnelDetail pro) async {
    final controller = TextEditingController();
    final message = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Écrire à ${pro.summary.displayName}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 4,
          maxLength: 1000,
          decoration: const InputDecoration(hintText: 'Votre message'),
        ),
        actions: [
          AppButton.ghost(
            text: 'Annuler',
            onPressed: () => Navigator.pop(context),
          ),
          AppButton(
            text: 'Envoyer',
            isFullWidth: false,
            size: AppButtonSize.compact,
            onPressed: () => Navigator.pop(context, controller.text.trim()),
          ),
        ],
      ),
    );
    controller.dispose();
    if (message == null || message.isEmpty || !context.mounted) return;
    try {
      final conversation = await ref
          .read(messagerieRepositoryProvider)
          .contacter(professionnelId: pro.id, message: message);
      if (!context.mounted) return;
      context.push(
        AppRoutes.conversation(conversation.id),
        extra: {'name': pro.summary.displayName, 'role': pro.summary.type},
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

class _PhotoParDefaut extends StatelessWidget {
  final ProfessionnelDetail pro;
  final Color color;
  const _PhotoParDefaut({required this.pro, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color.withValues(alpha: 0.85),
      alignment: Alignment.center,
      child: Icon(
        pro.summary.isAvocat ? Icons.gavel_rounded : Icons.psychology_rounded,
        size: 88,
        color: Colors.white.withValues(alpha: 0.9),
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
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
              fontFamily: 'Montserrat',
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
                  texte:
                      '${s.noteMoyenne!.toStringAsFixed(1)} (${s.nombreAvis} avis)',
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
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  final IconData icone;
  final String texte;
  final Color couleur;
  const _Info({
    required this.icone,
    required this.texte,
    this.couleur = const Color(0xFF9CA3AF),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icone, size: 16, color: couleur),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            texte,
            style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
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
      color: const Color(0xFFF9FAFC),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFEFF2F7),
          borderRadius: BorderRadius.circular(22),
        ),
        child: TabBar(
          indicator: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: const Color(0xFF111827),
          unselectedLabelColor: const Color(0xFF6B7280),
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          tabs: const [
            Tab(text: 'Présentation'),
            Tab(text: 'Tarifs'),
            Tab(text: 'Disponibilités'),
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
        const _Section('À propos'),
        Text(
          bio.isNotEmpty
              ? bio
              : 'Ce professionnel n’a pas encore rédigé de présentation.',
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: bio.isNotEmpty
                ? const Color(0xFF374151)
                : const Color(0xFF9CA3AF),
          ),
        ),
        if (pro.adresse != null && pro.adresse!.isNotEmpty) ...[
          const SizedBox(height: 20),
          const _Section('Adresse du cabinet'),
          Text(
            pro.adresse!,
            style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
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
      return const AppEmptyStateView(
        icon: Icons.folder_shared_outlined,
        title: 'Honoraires sur dossier',
        message:
            'L’avocat vous communique ses honoraires lorsqu’il accepte votre dossier.',
      );
    }
    if (pro.tarifs.isEmpty) {
      return const AppEmptyStateView(
        icon: Icons.sell_outlined,
        title: 'Aucun tarif publié',
        message:
            'Ce professionnel n’a pas encore publié de tarif : la réservation n’est pas encore possible.',
      );
    }
    final avocat = pro.summary.isAvocat;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (avocat)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Tarifs indicatifs. Les honoraires définitifs vous sont proposés lorsque l’avocat accepte votre dossier.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
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
                color: actif ? primaryColor : const Color(0xFFE5E7EB),
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
  const _Disponibilites({
    required this.professionnelId,
    required this.primaryColor,
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
          return const AppEmptyStateView(
            icon: Icons.event_busy_rounded,
            title: 'Aucun créneau disponible',
            message:
                'Les nouvelles disponibilités apparaîtront ici automatiquement.',
          );
        }
        final parJour = <DateTime, List<Creneau>>{};
        for (final c in libres) {
          parJour.putIfAbsent(c.jour, () => []).add(c);
        }
        final jours = parJour.keys.toList()..sort();
        return ListView(
          padding: const EdgeInsets.all(20),
          children: jours.map((jour) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Section(Formatters.formatJourLong(jour)),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: parJour[jour]!
                        .map(
                          (c) => Chip(
                            label: Text(Formatters.formatHeure(c.debut)),
                            backgroundColor: primaryColor.withValues(
                              alpha: 0.08,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            );
          }).toList(),
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
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Color(0xFF111827),
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

  const _BarreAction({
    required this.pro,
    required this.primaryColor,
    required this.tarif,
    required this.onEcrire,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avocat = pro.summary.isAvocat;
    final VoidCallback? action;
    final String libelle;
    if (avocat) {
      libelle = 'Soumettre un dossier';
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
          ? 'Prendre rendez-vous'
          : (pro.tarifs.isEmpty
                ? 'Réservation indisponible'
                : 'Choisissez un tarif');
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
        color: Colors.white,
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
              tooltip: 'Écrire',
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
