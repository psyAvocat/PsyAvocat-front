import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/theme/universe_provider.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../notifications/presentation/controllers/notifications_controller.dart';
import '../../../referentiels/presentation/widgets/specialite_filter_chips.dart';
import '../../data/models/professionnel_summary.dart';
import '../controllers/professionnels_controller.dart';
import '../widgets/professionnel_card.dart';

/// Onglet « Avocats » ou « Psychologues » — maquettes du même nom.
///
/// Données : GET /api/professionnels?type=AVOCAT|PSYCHOLOGUE (professionnels
/// validés de l'univers actif uniquement). La recherche et le filtre par
/// spécialité s'appliquent à cette liste réelle.
class ProfessionnelsListScreen extends ConsumerStatefulWidget {
  const ProfessionnelsListScreen({super.key});

  @override
  ConsumerState<ProfessionnelsListScreen> createState() =>
      _ProfessionnelsListScreenState();
}

class _ProfessionnelsListScreenState
    extends ConsumerState<ProfessionnelsListScreen> {
  String _query = '';
  String? _specialiteId;
  String? _specialiteNom;

  /// Professionnels correspondant à la recherche et à la spécialité choisie.
  List<ProfessionnelSummary> _filter(List<ProfessionnelSummary> list) {
    final query = _query.trim().toLowerCase();
    return list.where((pro) {
      final matchesSpecialite =
          _specialiteNom == null || pro.specialites.contains(_specialiteNom);
      final matchesQuery =
          query.isEmpty ||
          pro.fullName.toLowerCase().contains(query) ||
          pro.specialites.any((s) => s.toLowerCase().contains(query));
      return matchesSpecialite && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final universe = ref.watch(currentUniverseProvider);
    final professionnels = ref.watch(professionnelsByUniverseProvider);
    final unreadCount = ref.watch(unreadNotificationsBadgeProvider);
    final label = universe.professionalsLabel;

    return Scaffold(
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
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s16,
              AppSpacing.s8,
              AppSpacing.s16,
              AppSpacing.s8,
            ),
            child: SearchBar(
              hintText: universe.isPsychologist
                  ? 'Rechercher un psychologue…'
                  : 'Rechercher un avocat…',
              leading: const Icon(Icons.search_rounded),
              elevation: const WidgetStatePropertyAll(0),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          SpecialiteFilterChips(
            selectedId: _specialiteId,
            onSelected: (specialite) => setState(() {
              _specialiteId = specialite?.id;
              _specialiteNom = specialite?.nom;
            }),
          ),
          Expanded(
            child: AppAsyncView<List<ProfessionnelSummary>>(
              value: professionnels,
              isEmpty: (list) => list.isEmpty,
              emptyTitle: 'Aucun professionnel pour le moment',
              emptyMessage:
                  'Aucun ${label.toLowerCase()} n’est disponible actuellement.',
              emptyIcon: Icons.person_search_outlined,
              onRetry: () => ref.invalidate(professionnelsByUniverseProvider),
              builder: (list) {
                final filtered = _filter(list);
                if (filtered.isEmpty) {
                  return const AppEmptyStateView(
                    title: 'Aucun résultat',
                    message: 'Modifiez votre recherche ou la spécialité.',
                    icon: Icons.search_off_rounded,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.refresh(professionnelsByUniverseProvider.future),
                  child: ListView.separated(
                    // Marge basse : la barre de navigation flotte au-dessus.
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.s16,
                      AppSpacing.s8,
                      AppSpacing.s16,
                      120,
                    ),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (context, index) => ProfessionnelCard(
                      professionnel: filtered[index],
                      onTap: () => context.push(
                        AppRoutes.professionnel(filtered[index].id),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
