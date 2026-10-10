import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../controllers/create_dossier_wizard_controller.dart';
import '../../../../professionnels/data/models/professionnel_summary.dart';

class StepAvocats extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  final Color primaryColor;
  final bool isAvocat;

  const StepAvocats({
    super.key,
    required this.onNext,
    required this.primaryColor,
    required this.isAvocat,
  });

  @override
  ConsumerState<StepAvocats> createState() => _StepAvocatsState();
}

class _StepAvocatsState extends ConsumerState<StepAvocats> {
  final _searchController = TextEditingController();

  // Mock professionals for UI demonstration, since search endpoint isn't wired to state yet
  final List<ProfessionnelSummary> _mockPros = [
    ProfessionnelSummary(
      id: '1',
      fullName: 'Abdoulaye Traoré',
      type: 'AVOCAT',
      specialites: ['Droit immobilier'],
      noteMoyenne: 4.8,
      nombreAvis: 12,
      photoUrl: null,
    ),
    ProfessionnelSummary(
      id: '2',
      fullName: 'Fatoumata Diallo',
      type: 'AVOCAT',
      specialites: ['Droit de la famille'],
      noteMoyenne: 4.9,
      nombreAvis: 24,
      photoUrl: null,
    ),
    ProfessionnelSummary(
      id: '3',
      fullName: 'Mamadou Cissé',
      type: 'AVOCAT',
      specialites: ['Droit pénal'],
      noteMoyenne: 4.5,
      nombreAvis: 8,
      photoUrl: null,
    ),
    ProfessionnelSummary(
      id: '4',
      fullName: 'Aïssata Konaté',
      type: 'AVOCAT',
      specialites: ['Droit des affaires'],
      noteMoyenne: 4.7,
      nombreAvis: 19,
      photoUrl: null,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createDossierWizardProvider);
    final selectedPros = state.selectedProfessionnels;

    final allPros = _mockPros
        .where(
          (p) => widget.isAvocat ? p.type == 'AVOCAT' : p.type == 'PSYCHOLOGUE',
        )
        .toList();
    final otherPros = allPros
        .where((p) => !selectedPros.any((s) => s.id == p.id))
        .toList();

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              // Search Bar
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: widget.isAvocat
                              ? 'Rechercher un avocat par nom, spécialité...'
                              : 'Rechercher un psy par nom, spécialité...',
                          hintStyle: const TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 13,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: Color(0xFF6B7280),
                            size: 20,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: const Icon(
                      Icons.filter_list_rounded,
                      color: Color(0xFF111827),
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (selectedPros.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${widget.isAvocat ? 'Avocats' : 'Psychologues'} sélectionnés (${selectedPros.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    Text(
                      'Voir tout',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: widget.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...selectedPros.map((p) => _buildProCard(p, true)),
                const SizedBox(height: 24),
              ],

              Text(
                'Autres ${widget.isAvocat ? 'avocats' : 'psychologues'}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 12),
              ...otherPros.map((p) => _buildProCard(p, false)),
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
          child: AppButton(
            text: 'Suivant',
            onPressed: selectedPros.isNotEmpty ? widget.onNext : null,
            color: widget.primaryColor,
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
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.isAvocat ? 'Avocat' : 'Psychologue'} • ${p.specialites.isNotEmpty ? p.specialites.first : 'Généraliste'}',
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
