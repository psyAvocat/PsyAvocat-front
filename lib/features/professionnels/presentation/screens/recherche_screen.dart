import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../shared/models/specialite.dart';
import '../../data/models/professionnel_summary.dart';
import '../controllers/professionnels_controller.dart';
import '../widgets/professionnel_card.dart';

class RechercheScreen extends ConsumerStatefulWidget {
  const RechercheScreen({super.key});

  @override
  ConsumerState<RechercheScreen> createState() => _RechercheScreenState();
}

class _RechercheScreenState extends ConsumerState<RechercheScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedSpecialiteId;
  ProfessionnelSort _selectedSort = ProfessionnelSort.pertinence;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final query = (
      q: _searchQuery.isEmpty ? null : _searchQuery,
      specialiteId: _selectedSpecialiteId,
      tri: _selectedSort,
    );
    final professionnelsAsync = ref.watch(professionnelsProvider(query));
    final specialitesAsync = ref.watch(specialitesProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Rechercher un professionnel...',
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
          ),
          onChanged: _onSearchChanged,
        ),
        actions: [
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                _onSearchChanged('');
              },
            ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(specialitesAsync),
          Expanded(
            child: AppAsyncView<List<ProfessionnelSummary>>(
              value: professionnelsAsync,
              isEmpty: (list) => list.isEmpty,
              emptyTitle: 'Aucun résultat',
              emptyMessage: 'Aucun professionnel ne correspond à votre recherche.',
              emptyIcon: Icons.search_off,
              onRetry: () => ref.invalidate(professionnelsProvider(query)),
              builder: (list) => ListView.separated(
                padding: AppSpacing.screenPadding,
                itemCount: list.length,
                separatorBuilder: (_, _) => AppSpacing.vGap12,
                itemBuilder: (context, index) {
                  final pro = list[index];
                  return ProfessionnelCard(
                    professionnel: pro,
                    onTap: () => context.push('/professionnels/${pro.id}'),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(AsyncValue<List<Specialite>> specialitesAsync) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16, vertical: AppSpacing.s8),
      child: Row(
        children: [
          Expanded(
            child: specialitesAsync.when(
              data: (specialites) => DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  isExpanded: true,
                  hint: const Text('Spécialité'),
                  value: _selectedSpecialiteId,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Toutes spécialités'),
                    ),
                    ...specialites.map((s) => DropdownMenuItem(
                          value: s.id,
                          child: Text(s.nom),
                        )),
                  ],
                  onChanged: (val) => setState(() => _selectedSpecialiteId = val),
                ),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Erreur'),
            ),
          ),
          AppSpacing.hGap16,
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<ProfessionnelSort>(
                isExpanded: true,
                value: _selectedSort,
                items: const [
                  DropdownMenuItem(
                    value: ProfessionnelSort.pertinence,
                    child: Text('Pertinence'),
                  ),
                  DropdownMenuItem(
                    value: ProfessionnelSort.nom,
                    child: Text('Nom (A-Z)'),
                  ),
                  DropdownMenuItem(
                    value: ProfessionnelSort.note,
                    child: Text('Note (Décroissant)'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedSort = val);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
