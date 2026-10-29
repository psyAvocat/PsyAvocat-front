import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/theme/universe_provider.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../referentiels/presentation/widgets/specialite_filter_chips.dart';
import '../../data/models/professionnel_summary.dart';
import '../controllers/professionnels_controller.dart';
import '../widgets/professionnel_card.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/l10n/app_strings.dart';

/// Recherche de professionnels (ouverte depuis la barre de recherche de
/// l'accueil). Même présentation que la liste des professionnels : barre de
/// recherche arrondie, puces de spécialités, cartes séparées par un trait.
/// La recherche, le filtre et le tri sont faits par le serveur.
class RechercheScreen extends ConsumerStatefulWidget {
  const RechercheScreen({super.key});

  @override
  ConsumerState<RechercheScreen> createState() => _RechercheScreenState();
}

class _RechercheScreenState extends ConsumerState<RechercheScreen> {
  final _searchController = TextEditingController();
  String? _specialiteId;
  ProfessionnelSort _tri = ProfessionnelSort.pertinence;
  String _recherche = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _libelleTri(ProfessionnelSort tri) => switch (tri) {
    ProfessionnelSort.pertinence => tr('Pertinence'),
    ProfessionnelSort.nom => tr('Nom (A-Z)'),
    ProfessionnelSort.note => tr('Mieux notés'),
  };

  @override
  Widget build(BuildContext context) {
    final universe = ref.watch(currentUniverseProvider);
    final query = (
      q: _recherche.trim().isEmpty ? null : _recherche.trim(),
      specialiteId: _specialiteId,
      tri: _tri,
    );
    final professionnels = ref.watch(professionnelsProvider(query));

    return Scaffold(
      appBar: AppPageHeader(
        title: tr('Rechercher'),
        trailing: PopupMenuButton<ProfessionnelSort>(
          tooltip: tr('Trier'),
          icon: const Icon(Icons.sort_rounded),
          initialValue: _tri,
          onSelected: (tri) => setState(() => _tri = tri),
          itemBuilder: (context) => [
            for (final tri in ProfessionnelSort.values)
              CheckedPopupMenuItem(
                value: tri,
                checked: tri == _tri,
                child: Text(_libelleTri(tri)),
              ),
          ],
        ),
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
            child: AppSearchField(
              controller: _searchController,
              autofocus: true,
              effacable: true,
              hintText: universe.isPsychologist
                  ? tr('Rechercher un psychologue…')
                  : tr('Rechercher un avocat…'),
              onChanged: (value) => setState(() => _recherche = value),
            ),
          ),
          SpecialiteFilterChips(
            selectedId: _specialiteId,
            onSelected: (specialite) =>
                setState(() => _specialiteId = specialite?.id),
          ),
          Expanded(
            child: AppAsyncView<List<ProfessionnelSummary>>(
              value: professionnels,
              isEmpty: (list) => list.isEmpty,
              emptyTitle: tr('Aucun résultat'),
              emptyMessage: tr('Modifiez votre recherche ou la spécialité.'),
              emptyIcon: Icons.search_off_rounded,
              onRetry: () => ref.invalidate(professionnelsProvider(query)),
              builder: (list) => ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s16,
                  AppSpacing.s8,
                  AppSpacing.s16,
                  AppSpacing.s32,
                ),
                itemCount: list.length,
                separatorBuilder: (_, _) => const Divider(),
                itemBuilder: (context, index) => ProfessionnelCard(
                  professionnel: list[index],
                  onTap: () =>
                      context.push(AppRoutes.professionnel(list[index].id)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
