import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/errors/user_message.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_state_views.dart';
import '../../../../professionnels/data/models/professionnel_summary.dart';
import '../../../../professionnels/presentation/controllers/professionnels_controller.dart';
import '../../controllers/create_dossier_wizard_controller.dart';

/// Étape 1 : choix des avocats destinataires parmi les avocats validés
/// (recherche réelle `GET /api/professionnels?type=AVOCAT`).
class StepAvocats extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  final Color primaryColor;

  const StepAvocats({
    super.key,
    required this.onNext,
    required this.primaryColor,
  });

  @override
  ConsumerState<StepAvocats> createState() => _StepAvocatsState();
}

class _StepAvocatsState extends ConsumerState<StepAvocats> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createDossierWizardProvider);
    final selectedPros = state.selectedProfessionnels;
    final query = (
      q: _query.isEmpty ? null : _query,
      specialiteId: null,
      tri: ProfessionnelSort.nom,
    );
    final avocatsAsync = ref.watch(professionnelsProvider(query));

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              TextField(
                controller: _searchController,
                onChanged: _onSearch,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Rechercher un avocat par nom, ville, spécialité…',
                  hintStyle: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF6B7280),
                    size: 20,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (selectedPros.isNotEmpty) ...[
                Text(
                  'Avocats sélectionnés (${selectedPros.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 12),
                ...selectedPros.map((p) => _buildProCard(p, true)),
                const SizedBox(height: 24),
              ],
              const Text(
                'Avocats disponibles',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 12),
              avocatsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => AppErrorStateView(
                  message: userMessageFor(e),
                  onRetry: () => ref.invalidate(professionnelsProvider(query)),
                ),
                data: (avocats) {
                  final autres = avocats
                      .where((p) => !selectedPros.any((s) => s.id == p.id))
                      .toList();
                  if (autres.isEmpty) {
                    return AppEmptyStateView(
                      icon: Icons.person_search_outlined,
                      title: _query.isEmpty
                          ? 'Aucun autre avocat disponible'
                          : 'Aucun avocat trouvé',
                      message: _query.isEmpty
                          ? null
                          : 'Essayez un autre nom, une ville ou une spécialité.',
                    );
                  }
                  return Column(
                    children: autres
                        .map((p) => _buildProCard(p, false))
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Color(0x0A000000),
                offset: Offset(0, -4),
                blurRadius: 10,
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: AppButton(
              text: 'Suivant',
              onPressed: selectedPros.isNotEmpty ? widget.onNext : null,
              color: widget.primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProCard(ProfessionnelSummary p, bool isSelected) {
    return GestureDetector(
      onTap: () =>
          ref.read(createDossierWizardProvider.notifier).toggleProfessionnel(p),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF3F4F6) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? null
              : Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: widget.primaryColor.withValues(alpha: 0.1),
              backgroundImage: p.photoUrl != null
                  ? NetworkImage(p.photoUrl!)
                  : null,
              child: p.photoUrl == null
                  ? Text(
                      p.fullName.isNotEmpty ? p.fullName[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: widget.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (p.specialites.isNotEmpty) p.specialites.first,
                      if (p.ville != null && p.ville!.isNotEmpty) p.ville!,
                    ].join(' • '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? widget.primaryColor : Colors.white,
                border: Border.all(
                  color: isSelected
                      ? widget.primaryColor
                      : const Color(0xFFD1D5DB),
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
