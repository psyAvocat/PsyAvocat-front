import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/errors/user_message.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/theme/universe_provider.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../data/models/dossier_model.dart';
import '../controllers/create_dossier_wizard_controller.dart';
import '../controllers/dossiers_controller.dart';
import '../widgets/dossier_ui.dart';
import 'create_dossier_wizard_screen.dart';
import '../../../../core/l10n/app_strings.dart';

/// Filtre des onglets : tous, en attente (aucune réponse), répondu.
enum _Filtre { tous, enAttente, repondu }

bool _estRepondu(DossierModel d) => d.estPrisEnCharge || d.nombreReponses > 0;

/// « Mes dossiers » — maquette Figma : suivi réel des envois aux avocats
/// (GET /api/dossiers), filtres, recherche, et consultation de chaque dossier.
class DossiersScreen extends ConsumerStatefulWidget {
  const DossiersScreen({super.key});

  @override
  ConsumerState<DossiersScreen> createState() => _DossiersScreenState();
}

class _DossiersScreenState extends ConsumerState<DossiersScreen> {
  _Filtre _filtre = _Filtre.tous;
  String _recherche = '';

  /// Domaine choisi via le bouton de filtre (null = tous).
  String? _domaine;

  void _nouveauDossier() {
    ref.read(createDossierWizardProvider.notifier).clear();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateDossierWizardScreen()),
    );
  }

  List<DossierModel> _filtrer(List<DossierModel> dossiers) {
    final q = _recherche.trim().toLowerCase();
    return dossiers.where((d) {
      final filtreOk = switch (_filtre) {
        _Filtre.tous => true,
        _Filtre.enAttente => !_estRepondu(d),
        _Filtre.repondu => _estRepondu(d),
      };
      final domaineOk = _domaine == null || d.domaineNom == _domaine;
      final rechercheOk =
          q.isEmpty ||
          d.titre.toLowerCase().contains(q) ||
          (d.domaineNom?.toLowerCase().contains(q) ?? false) ||
          d.soumissions.any((s) => s.displayName.toLowerCase().contains(q));
      return filtreOk && domaineOk && rechercheOk;
    }).toList();
  }

  Future<void> _choisirDomaine(List<DossierModel> dossiers) async {
    final domaines =
        dossiers.map((d) => d.domaineNom).whereType<String>().toSet().toList()
          ..sort();
    final choix = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: context.palette.card,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                tr('Domaine du droit'),
                style: AppTypography.petitTitre,
              ),
            ),
            for (final domaine in ['', ...domaines])
              ListTile(
                title: Text(
                  domaine.isEmpty ? tr('Tous les domaines') : domaine,
                ),
                trailing: domaine == (_domaine ?? '')
                    ? Icon(Icons.check_rounded, color: context.colors.primary)
                    : null,
                onTap: () => Navigator.pop(context, domaine),
              ),
            AppSpacing.vGap8,
          ],
        ),
      ),
    );
    if (choix != null) setState(() => _domaine = choix.isEmpty ? null : choix);
  }

  @override
  Widget build(BuildContext context) {
    final universe = ref.watch(currentUniverseProvider);
    final dossiersAsync = ref.watch(dossiersListProvider);

    return Scaffold(
      backgroundColor: context.palette.card,
      appBar: AppPageHeader(title: tr('Mes dossiers')),
      body: dossiersAsync.when(
        loading: () => AppLoadingView(universe: universe),
        error: (e, _) => AppErrorStateView(
          title: tr('Impossible de charger vos dossiers'),
          message: userMessageFor(e),
          onRetry: () => ref.read(dossiersListProvider.notifier).refresh(),
        ),
        data: (dossiers) {
          if (dossiers.isEmpty) {
            return AppEmptyStateView(
              icon: Icons.folder_open_rounded,
              title: tr('Aucun dossier en cours'),
              message: tr(
                'Déposez votre premier dossier juridique pour le soumettre aux avocats de votre choix.',
              ),
              actionText: tr('Créer un dossier'),
              onAction: _nouveauDossier,
            );
          }
          final visibles = _filtrer(dossiers);
          final enAttente = dossiers.where((d) => !_estRepondu(d)).length;
          return RefreshIndicator(
            onRefresh: () => ref.read(dossiersListProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 24, 18, 32),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        tr('Suivez vos envois et les réponses des avocats.'),
                        style: AppTypography.texteSecondaire.copyWith(
                          color: context.palette.textMuted,
                        ),
                      ),
                    ),
                    AppSpacing.hGap12,
                    Semantics(
                      button: true,
                      label: tr('Nouveau dossier'),
                      child: Material(
                        color: AppColors.lawyer,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _nouveauDossier,
                          child: const SizedBox(
                            width: 40,
                            height: 40,
                            child: Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                AppSpacing.vGap20,
                Row(
                  children: [
                    _Onglet(
                      label: tr('Tous ({n})', {'n': dossiers.length}),
                      actif: _filtre == _Filtre.tous,
                      onTap: () => setState(() => _filtre = _Filtre.tous),
                    ),
                    AppSpacing.hGap8,
                    _Onglet(
                      label: tr('En attente ({n})', {'n': enAttente}),
                      actif: _filtre == _Filtre.enAttente,
                      onTap: () => setState(() => _filtre = _Filtre.enAttente),
                    ),
                    AppSpacing.hGap8,
                    _Onglet(
                      label: tr('Répondu ({n})', {
                        'n': dossiers.length - enAttente,
                      }),
                      actif: _filtre == _Filtre.repondu,
                      onTap: () => setState(() => _filtre = _Filtre.repondu),
                    ),
                  ],
                ),
                AppSpacing.vGap12,
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: TextField(
                          onChanged: (v) => setState(() => _recherche = v),
                          // Toucher ailleurs : champ neutre, clavier fermé.
                          onTapOutside: (_) =>
                              FocusManager.instance.primaryFocus?.unfocus(),
                          style: AppTypography.texte.copyWith(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: tr('Rechercher un dossier...'),
                            hintStyle: AppTypography.texte.copyWith(
                              fontSize: 13,
                              color: context.palette.textMuted,
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              size: 20,
                              color: context.palette.textMuted,
                            ),
                            contentPadding: EdgeInsets.zero,
                            filled: true,
                            fillColor: context.palette.card,
                            enabledBorder: _bordure(
                              context.palette.borderTinted,
                            ),
                            focusedBorder: _bordure(context.colors.primary),
                          ),
                        ),
                      ),
                    ),
                    AppSpacing.hGap8,
                    Semantics(
                      button: true,
                      label: tr('Filtrer par domaine'),
                      child: InkWell(
                        onTap: () => _choisirDomaine(dossiers),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: _domaine != null
                                ? context.palette.chip
                                : context.palette.card,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: context.palette.borderTinted,
                            ),
                          ),
                          child: Icon(
                            Icons.filter_list_rounded,
                            size: 20,
                            color: context.colors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                AppSpacing.vGap12,
                if (visibles.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Text(
                      tr('Aucun dossier ne correspond à votre recherche.'),
                      textAlign: TextAlign.center,
                      style: AppTypography.texteSecondaire,
                    ),
                  )
                else
                  for (final dossier in visibles) ...[
                    _DossierCard(dossier: dossier),
                    AppSpacing.vGap12,
                  ],
              ],
            ),
          );
        },
      ),
    );
  }

  static OutlineInputBorder _bordure(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide(color: color),
  );
}

class _Onglet extends StatelessWidget {
  final String label;
  final bool actif;
  final VoidCallback onTap;

  const _Onglet({
    required this.label,
    required this.actif,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        selected: actif,
        button: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: actif ? AppColors.lawyer : context.palette.chip,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.texte.copyWith(
                fontSize: 13,
                color: actif ? Colors.white : context.palette.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DossierCard extends StatelessWidget {
  final DossierModel dossier;

  const _DossierCard({required this.dossier});

  @override
  Widget build(BuildContext context) {
    final envoi = libelleEnvoi(dossier);
    final retenue = dossier.soumissionRetenue;
    // Dossier confié : seul l'avocat qui l'a accepté est cité.
    final avocats = retenue != null
        ? tr('Pris en charge par {avocat}', {'avocat': retenue.displayName})
        : dossier.soumissions.map((s) => s.displayName).join(' · ');
    final pieces = dossier.piecesJointes.length;

    return DossierCardContainer(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DossierIconBadge(),
          AppSpacing.hGap12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dossier.titre,
                  style: AppTypography.texteSemiBold.copyWith(
                    fontSize: 15,
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
                AppSpacing.vGap12,
                if (envoi != null)
                  Text(envoi, style: DossierText.secondaire(context)),
                if (avocats.isNotEmpty) ...[
                  AppSpacing.vGap4,
                  Text(avocats, style: DossierText.secondaire(context)),
                ],
                AppSpacing.vGap8,
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DossierStatutBadge(dossier: dossier),
                          if (pieces > 0) ...[
                            AppSpacing.vGap4,
                            Row(
                              children: [
                                Icon(
                                  Icons.attach_file_rounded,
                                  size: 14,
                                  color: context.palette.textMuted,
                                ),
                                Text(
                                  ' ${piecesJointesLabel(pieces)}',
                                  style: DossierText.petit(context),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    FilledButton(
                      onPressed: () => context.push(
                        retenue != null
                            ? AppRoutes.dossierPriseEnCharge(dossier.id)
                            : AppRoutes.dossier(dossier.id),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.lawyer,
                        minimumSize: const Size(92, 30),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        textStyle: AppTypography.texte.copyWith(fontSize: 13),
                      ),
                      child: Text(tr('Consulter')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
