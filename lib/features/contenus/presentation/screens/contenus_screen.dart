import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/theme/universe_provider.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../notifications/presentation/controllers/notifications_controller.dart';
import '../../../referentiels/presentation/widgets/specialite_filter_chips.dart';
import '../../data/models/contenu_model.dart';
import '../../data/repositories/contenus_repository.dart';
import '../controllers/contenus_controller.dart';
import '../widgets/publication_cards.dart';

/// Onglet « Articles » (univers Avocat) ou « Conseils » (univers Psychologue) —
/// maquettes « Articles » et « Conseils ».
///
/// Données : GET /api/contenus?type=ARTICLE|CONSEIL (publications des
/// professionnels validés). Recherche, catégorie et tri sont traités par l'API.
class ContenusScreen extends ConsumerStatefulWidget {
  const ContenusScreen({super.key});

  @override
  ConsumerState<ContenusScreen> createState() => _ContenusScreenState();
}

class _ContenusScreenState extends ConsumerState<ContenusScreen> {
  /// Délai après la dernière frappe avant d'interroger l'API.
  static const _searchDebounce = Duration(milliseconds: 400);

  Timer? _debounce;
  String? _query;
  String? _specialiteId;
  PublicationSort _tri = PublicationSort.populaire;

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

  bool get _hasFilters => _query != null || _specialiteId != null;

  @override
  Widget build(BuildContext context) {
    final universe = ref.watch(currentUniverseProvider);
    final label = publicationsLabelFor(universe);
    final unreadCount = ref.watch(unreadNotificationsBadgeProvider);
    final publications = ref.watch(
      publicationsProvider((q: _query, specialiteId: _specialiteId, tri: _tri)),
    );

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(label),
          actions: [
            IconButton(
              tooltip: 'Notifications',
              onPressed: () => context.push(AppRoutes.notifications),
              icon: Badge(
                isLabelVisible: unreadCount > 0,
                label: Text('$unreadCount'),
                child: const Icon(Icons.notifications_outlined),
              ),
            ),
          ],
          // Tri « Populaires / Récents » (maquette Conseils).
          bottom: TabBar(
            onTap: (index) => setState(
              () => _tri = index == 0
                  ? PublicationSort.populaire
                  : PublicationSort.recent,
            ),
            tabs: const [
              Tab(text: 'Populaires'),
              Tab(text: 'Récents'),
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
                    ? 'Rechercher un article…'
                    : 'Rechercher un conseil…',
                leading: const Icon(Icons.search_rounded),
                elevation: const WidgetStatePropertyAll(0),
                onChanged: _onSearchChanged,
              ),
            ),
            SpecialiteFilterChips(
              selectedId: _specialiteId,
              onSelected: (specialite) =>
                  setState(() => _specialiteId = specialite?.id),
            ),
            AppSpacing.vGap8,
            Expanded(
              child: AppAsyncView<List<Publication>>(
                value: publications,
                isEmpty: (list) => list.isEmpty,
                emptyTitle: _hasFilters
                    ? 'Aucun résultat'
                    : (universe.isLawyer
                          ? 'Aucun article publié'
                          : 'Aucun conseil publié'),
                emptyMessage: _hasFilters
                    ? 'Modifiez votre recherche ou la catégorie.'
                    : 'Les ${label.toLowerCase()} publiés par nos professionnels apparaîtront ici.',
                emptyIcon: universe.isLawyer
                    ? Icons.menu_book_outlined
                    : Icons.lightbulb_outline_rounded,
                onRetry: () => ref.invalidate(publicationsProvider),
                builder: (list) => RefreshIndicator(
                  onRefresh: () async => ref.invalidate(publicationsProvider),
                  child: ListView.separated(
                    // Marge basse : la barre de navigation flotte au-dessus.
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.s16,
                      AppSpacing.s8,
                      AppSpacing.s16,
                      120,
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
