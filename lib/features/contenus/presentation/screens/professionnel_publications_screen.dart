import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/theme/universe_provider.dart';
import '../../../../core/widgets/app_async_view.dart';
import '../../data/models/contenu_model.dart';
import '../../data/repositories/contenus_repository.dart';
import '../controllers/contenus_controller.dart';
import '../widgets/publication_cards.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/widgets/app_back_button.dart';

/// Articles (avocat) ou conseils (psychologue) publiés par un professionnel,
/// ouverts depuis sa fiche (« Voir les articles ») ou depuis la fin d'une
/// lecture (« Voir ses autres articles »).
///
/// Recherche (titre, résumé) et tri « Populaires / Récents » comme dans
/// l'onglet Articles / Conseils, traités par l'API.
class ProfessionnelPublicationsScreen extends ConsumerStatefulWidget {
  final String professionnelId;

  /// Nom affiché sous le titre (« Me Traoré ») ; facultatif.
  final String? professionnelNom;

  const ProfessionnelPublicationsScreen({
    super.key,
    required this.professionnelId,
    this.professionnelNom,
  });

  @override
  ConsumerState<ProfessionnelPublicationsScreen> createState() =>
      _ProfessionnelPublicationsScreenState();
}

class _ProfessionnelPublicationsScreenState
    extends ConsumerState<ProfessionnelPublicationsScreen> {
  /// Délai après la dernière frappe avant d'interroger l'API.
  static const _searchDebounce = Duration(milliseconds: 400);

  Timer? _debounce;
  String? _query;

  /// Publications d'un auteur : les plus récentes d'abord par défaut.
  PublicationSort _tri = PublicationSort.recent;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(_searchDebounce, () {
      if (mounted) setState(() => _query = value.trim().isEmpty ? null : value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final universe = ref.watch(currentUniverseProvider);
    final label = publicationsLabelFor(universe);
    final query = (auteurId: widget.professionnelId, q: _query, tri: _tri);
    final publications = ref.watch(professionnelPublicationsProvider(query));

    return DefaultTabController(
      length: 2,
      // Même ordre d'onglets que la page Articles / Conseils.
      initialIndex: 1,
      child: Scaffold(
        backgroundColor: context.palette.page,
        appBar: AppBar(
          backgroundColor: context.palette.card,
          surfaceTintColor: context.palette.card,
          elevation: 0,
          leading: const AppBackButton(),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr(label)),
              if (widget.professionnelNom != null)
                Text(
                  widget.professionnelNom!,
                  style: AppTypography.texteSecondaire,
                ),
            ],
          ),
          bottom: TabBar(
            onTap: (index) => setState(
              () => _tri = index == 0
                  ? PublicationSort.populaire
                  : PublicationSort.recent,
            ),
            tabs: [
              Tab(text: tr('Populaires')),
              Tab(text: tr('Récents')),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s16,
                AppSpacing.s16,
                AppSpacing.s16,
                AppSpacing.s8,
              ),
              child: SearchBar(
                hintText: universe.isLawyer
                    ? tr('Rechercher un article…')
                    : tr('Rechercher un conseil…'),
                leading: const Icon(Icons.search_rounded),
                elevation: const WidgetStatePropertyAll(0),
                onChanged: _onSearchChanged,
              ),
            ),
            Expanded(
              child: AppAsyncView<List<Publication>>(
                value: publications,
                isEmpty: (list) => list.isEmpty,
                emptyTitle: _query != null
                    ? tr('Aucun résultat')
                    : (universe.isLawyer
                          ? tr('Aucun article publié')
                          : tr('Aucun conseil publié')),
                emptyMessage: _query != null
                    ? tr('Modifiez votre recherche.')
                    : tr(
                        'Ce professionnel n’a encore rien publié. Revenez plus tard.',
                      ),
                emptyIcon: _query != null
                    ? Icons.search_off_rounded
                    : (universe.isLawyer
                          ? Icons.menu_book_outlined
                          : Icons.lightbulb_outline_rounded),
                onRetry: () =>
                    ref.invalidate(professionnelPublicationsProvider(query)),
                builder: (list) => RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(professionnelPublicationsProvider(query)),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.s16,
                      AppSpacing.s8,
                      AppSpacing.s16,
                      AppSpacing.s16,
                    ),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => AppSpacing.vGap12,
                    itemBuilder: (context, index) => PublicationListCard(
                      publication: list[index],
                      onTap: () =>
                          context.push(AppRoutes.contenu(list[index].id)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
