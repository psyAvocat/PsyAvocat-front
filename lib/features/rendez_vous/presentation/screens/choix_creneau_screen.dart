import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/universe_provider.dart';
import '../../../professionnels/data/models/professional_detail_model.dart';
import '../../../professionnels/data/repositories/professionnels_repository.dart';

/// Écran « Choix du créneau » (Étape 4) conforme à la maquette Figma.
/// Permet la sélection directe de la date, de la modalité (visio / cabinet) et du créneau horaire.
class ChoixCreneauScreen extends ConsumerStatefulWidget {
  final String professionnelId;
  final ProfessionalTarif? initialTarif;

  const ChoixCreneauScreen({
    super.key,
    required this.professionnelId,
    this.initialTarif,
  });

  @override
  ConsumerState<ChoixCreneauScreen> createState() => _ChoixCreneauScreenState();
}

class _ChoixCreneauScreenState extends ConsumerState<ChoixCreneauScreen> {
  int _selectedDayIndex = 1; // Par défaut Mardi 15
  String? _selectedCreneau = '10:00';
  String _mode = 'En ligne (visioconférence)'; // ou 'Au cabinet'
  late ProfessionalTarif? _tarif;

  @override
  void initState() {
    super.initState();
    _tarif = widget.initialTarif;
  }

  @override
  Widget build(BuildContext context) {
    final universe = ref.watch(currentUniverseProvider);
    final primaryColor = universe.primaryColor;
    final repo = ref.watch(professionnelsRepositoryProvider);

    return FutureBuilder<ProfessionalDetail?>(
      future: repo.getProfessionnelById(widget.professionnelId),
      builder: (context, snapshot) {
        final pro = snapshot.data;
        if (pro == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final jours = pro.disponibilites;
        final jourActif = (jours.isNotEmpty && _selectedDayIndex < jours.length)
            ? jours[_selectedDayIndex]
            : null;
        final creneauxDisponibles = jourActif?.creneaux ?? <String>[];

        final currentTarif = _tarif ?? (pro.tarifs.isNotEmpty ? pro.tarifs.first : null);

        return Scaffold(
          backgroundColor: const Color(0xFFF9FAFC),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                  color: const Color(0xFF1F2937),
                  onPressed: () => context.pop(),
                ),
              ),
            ),
            centerTitle: true,
            title: const Text(
              'Choix du créneau',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
                fontFamily: 'Montserrat',
              ),
            ),
          ),
          body: SafeArea(
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Carte résumé du professionnel
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.asset(
                                    pro.imagePath,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      width: 60,
                                      height: 60,
                                      color: primaryColor.withValues(alpha: 0.1),
                                      child: Icon(
                                        pro.isAvocat ? Icons.gavel_rounded : Icons.psychology_rounded,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ),
                                ),
                                if (pro.enLigne)
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF16A34A),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          pro.nom,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF111827),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: primaryColor.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          pro.isAvocat ? 'Avocat' : 'Psychologue',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: primaryColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
                                      const SizedBox(width: 3),
                                      Text(
                                        '${pro.note} (${pro.nombreAvis} avis)',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF4B5563),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${pro.ville} • ${pro.distance}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 2. Choix de la modalité (Visio vs Cabinet)
                      const Text(
                        'Modalité de consultation',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildModeOption(
                              label: 'En ligne (Visio)',
                              icon: Icons.videocam_rounded,
                              isSelected: _mode.contains('ligne'),
                              primaryColor: primaryColor,
                              onTap: () => setState(() => _mode = 'En ligne (visioconférence)'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildModeOption(
                              label: 'Au cabinet',
                              icon: Icons.business_rounded,
                              isSelected: _mode.contains('cabinet'),
                              primaryColor: primaryColor,
                              onTap: () => setState(() => _mode = 'Au cabinet (${pro.ville})'),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // 3. Section « Sélectionnez une date »
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Sélectionnez une date',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          Text(
                            'Avril 2025',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Carrousel horizontal des jours
                      SizedBox(
                        height: 90,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: jours.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final j = jours[index];
                            final isSelected = index == _selectedDayIndex;

                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedDayIndex = index;
                                  _selectedCreneau = j.creneaux.isNotEmpty ? j.creneaux.first : null;
                                });
                              },
                              borderRadius: BorderRadius.circular(18),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 64,
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSelected ? primaryColor : Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: isSelected ? primaryColor : const Color(0xFFE5E7EB),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isSelected
                                          ? primaryColor.withValues(alpha: 0.3)
                                          : Colors.black.withValues(alpha: 0.02),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      j.labelJour,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected ? Colors.white70 : const Color(0xFF6B7280),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      j.labelNumero,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: isSelected ? Colors.white : const Color(0xFF111827),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      j.labelMois,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w500,
                                        color: isSelected ? Colors.white70 : const Color(0xFF9CA3AF),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 28),

                      // 4. Section « Choisissez un créneau horaire »
                      const Text(
                        'Choisissez un créneau horaire',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      if (creneauxDisponibles.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Text(
                            'Aucun créneau horaire disponible pour cette date.',
                            style: TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        )
                      else
                        Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: creneauxDisponibles.map((creneau) {
                          final isSelected = creneau == _selectedCreneau;

                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedCreneau = creneau;
                              });
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 78,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? primaryColor : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected ? primaryColor : const Color(0xFFE5E7EB),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: isSelected
                                        ? primaryColor.withValues(alpha: 0.25)
                                        : Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  creneau,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                    color: isSelected ? Colors.white : const Color(0xFF374151),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 24),

                      // 5. Encadré Règle Métier & Acompte 20%
                      if (currentTarif != null)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: primaryColor.withValues(alpha: 0.15)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.shield_outlined, size: 20, color: primaryColor),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Réservation directe et sécurisée',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Créneau confirmé immédiatement. Un acompte légal obligatoire de 20% (${((currentTarif.montantFcfa * 0.20).round()).toString()} FCFA) est validé pour bloquer définitivement le créneau.',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFF4B5563),
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                // 6. Bouton d'action fixe en bas « Confirmer le rendez-vous »
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
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
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _selectedCreneau == null || jourActif == null
                            ? null
                            : () {
                                context.push(
                                  '/rendez-vous/confirmation',
                                  extra: {
                                    'pro': pro,
                                    'jour': jourActif,
                                    'creneau': _selectedCreneau!,
                                    'mode': _mode,
                                    'tarif': currentTarif,
                                  },
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          disabledBackgroundColor: const Color(0xFFE5E7EB),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                          ),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Confirmer le rendez-vous',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModeOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color primaryColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryColor : const Color(0xFFE5E7EB),
            width: isSelected ? 1.8 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? primaryColor : const Color(0xFF6B7280),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? primaryColor : const Color(0xFF374151),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
