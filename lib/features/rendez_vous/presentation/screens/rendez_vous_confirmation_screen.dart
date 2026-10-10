import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/universe_provider.dart';
import '../../../professionnels/data/models/professional_detail_model.dart';
import '../controllers/rendez_vous_controller.dart';
import '../../../../core/router/app_routes.dart';

/// Écran de confirmation du rendez-vous (Étape 5).
/// Enregistre le rendez-vous immédiatement en état 'Confirmé' avec son acompte de 20%,
/// et permet la navigation fluide vers la liste des rendez-vous ou l'accueil.
class RendezVousConfirmationScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> bookingData;

  const RendezVousConfirmationScreen({super.key, required this.bookingData});

  @override
  ConsumerState<RendezVousConfirmationScreen> createState() =>
      _RendezVousConfirmationScreenState();
}

class _RendezVousConfirmationScreenState
    extends ConsumerState<RendezVousConfirmationScreen> {
  bool _hasSaved = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _saveAppointment();
    });
  }

  void _saveAppointment() {
    if (_hasSaved) return;
    _hasSaved = true;

    final pro = widget.bookingData['pro'] as ProfessionalDetail?;
    final jour = widget.bookingData['jour'] as DisponibiliteJour?;
    final mode =
        widget.bookingData['mode'] as String? ?? 'En ligne (visioconférence)';
    final tarif = widget.bookingData['tarif'] as ProfessionalTarif?;

    if (pro != null && jour != null) {
      final total = tarif?.montantFcfa ?? 150000;
      final dispoId = widget.bookingData['disponibiliteId'] as String?;
      if (dispoId != null) {
        ref
            .read(rendezVousControllerProvider.notifier)
            .reserver(
              typeProfessionnel: pro.isAvocat ? 'AVOCAT' : 'PSYCHOLOGUE',
              professionnelId: pro.id,
              disponibiliteId: dispoId,
              mode: mode,
              montantTotal: total.toDouble(),
              motif: tarif?.titre,
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final universe = ref.watch(currentUniverseProvider);
    final primaryColor = universe.primaryColor;

    final pro = widget.bookingData['pro'] as ProfessionalDetail?;
    final jour = widget.bookingData['jour'] as DisponibiliteJour?;
    final creneau = widget.bookingData['creneau'] as String? ?? '10:00';
    final mode =
        widget.bookingData['mode'] as String? ?? 'En ligne (visioconférence)';
    final tarif = widget.bookingData['tarif'] as ProfessionalTarif?;
    final montantTotal = tarif?.montantFcfa ?? 150000;
    final acompte = (montantTotal * 0.20).round();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // 1. Icône de succès animée avec pastille colorée
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF86EFAC), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 50,
                  color: Color(0xFF16A34A),
                ),
              ),

              const SizedBox(height: 24),

              // Titre de confirmation
              const Text(
                'Rendez-vous confirmé !',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                  fontFamily: 'Montserrat',
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Votre consultation a été enregistrée directement dans l\'agenda du praticien selon les disponibilités sélectionnées.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 32),

              // 2. Carte récapitulative
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: const Color(0xFFE5E7EB),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Professionnel
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            pro?.imagePath ??
                                'assets/images/onboarding_lawyer.png',
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  width: 50,
                                  height: 50,
                                  color: primaryColor.withValues(alpha: 0.1),
                                  child: Icon(
                                    Icons.person,
                                    color: primaryColor,
                                  ),
                                ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pro?.nom ?? 'Professionnel',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              Text(
                                pro?.specialitePrincipale ?? 'Consultation',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Confirmé',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Divider(height: 28),

                    // Date & Heure
                    _buildDetailRow(
                      icon: Icons.calendar_today_rounded,
                      label: 'Date & Heure',
                      value:
                          '${jour?.labelJour ?? ""} ${jour?.labelNumero ?? ""} ${jour?.labelMois ?? ""} à $creneau',
                    ),
                    const SizedBox(height: 12),

                    // Modalité
                    _buildDetailRow(
                      icon: Icons.location_on_outlined,
                      label: 'Modalité',
                      value: mode,
                    ),
                    const SizedBox(height: 12),

                    // Tarification & Acompte 20%
                    _buildDetailRow(
                      icon: Icons.payments_outlined,
                      label: 'Honoraires totaux',
                      value: '${_formatPrice(montantTotal)} FCFA',
                    ),
                    const SizedBox(height: 12),

                    _buildDetailRow(
                      icon: Icons.check_circle_outline_rounded,
                      label: 'Acompte légal (20%)',
                      value: '${_formatPrice(acompte)} FCFA (Réglé)',
                      valueColor: const Color(0xFF16A34A),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // 3. Bouton principal « Voir mes rendez-vous »
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => context.go(AppRoutes.rendezVous),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Voir mes rendez-vous',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 4. Bouton secondaire « Retour à l'accueil »
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => context.go(AppRoutes.home),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: Color(0xFFE5E7EB),
                      width: 1.4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    'Retour à l\'accueil',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: valueColor ?? const Color(0xFF111827),
            ),
          ),
        ),
      ],
    );
  }

  String _formatPrice(int amount) {
    final s = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(s[i]);
    }
    return buffer.toString();
  }
}
