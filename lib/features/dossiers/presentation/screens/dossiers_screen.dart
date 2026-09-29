import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/universe_provider.dart';
import '../../data/models/dossier_model.dart';
import '../controllers/dossiers_controller.dart';

/// Écran « Mes dossiers juridiques » — liste en temps réel depuis GET /api/dossiers.
class DossiersScreen extends ConsumerWidget {
  const DossiersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final universe = ref.watch(currentUniverseProvider);
    final primaryColor = universe.primaryColor;
    final dossiersAsync = ref.watch(dossiersListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Mes dossiers',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
            fontFamily: 'Montserrat',
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_rounded, color: primaryColor, size: 28),
            onPressed: () => _showCreateDossierSheet(context, ref, primaryColor),
            tooltip: 'Nouveau dossier',
          ),
        ],
      ),
      body: SafeArea(
        child: dossiersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorState(
            onRetry: () => ref.read(dossiersListProvider.notifier).refresh(),
          ),
          data: (dossiers) {
            if (dossiers.isEmpty) {
              return _EmptyDossierState(
                primaryColor: primaryColor,
                onCreateTap: () => _showCreateDossierSheet(context, ref, primaryColor),
              );
            }
            return RefreshIndicator(
              onRefresh: () => ref.read(dossiersListProvider.notifier).refresh(),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                itemCount: dossiers.length,
                itemBuilder: (context, index) => _DossierCard(
                  dossier: dossiers[index],
                  primaryColor: primaryColor,
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDossierSheet(context, ref, primaryColor),
        backgroundColor: primaryColor,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Nouveau dossier',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  void _showCreateDossierSheet(BuildContext context, WidgetRef ref, Color primaryColor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateDossierSheet(primaryColor: primaryColor, ref: ref),
    );
  }
}

// ─── Carte dossier ─────────────────────────────────────────────────────────────
class _DossierCard extends StatelessWidget {
  final DossierModel dossier;
  final Color primaryColor;

  const _DossierCard({required this.dossier, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getStatusInfo(dossier.statut);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showDossierDetail(context, dossier, primaryColor),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dossier.reference.isNotEmpty ? '#${dossier.reference}' : 'Sans référence',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  _StatusBadge(label: statusInfo.$1, color: statusInfo.$2),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                dossier.titre,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              if (dossier.description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  dossier.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF4B5563),
                    height: 1.4,
                  ),
                ),
              ],
              if (dossier.soumissions.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(color: Color(0xFFF3F4F6)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.gavel_rounded, size: 16, color: primaryColor),
                    const SizedBox(width: 6),
                    Text(
                      '${dossier.soumissions.length} proposition(s) reçue(s)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _showDossierDetail(context, dossier, primaryColor),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: BorderSide(color: primaryColor, width: 1.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    dossier.soumissions.isEmpty
                        ? 'Voir le dossier'
                        : 'Consulter les propositions',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  (String, Color) _getStatusInfo(String statut) {
    switch (statut) {
      case 'EN_COURS':
        return ('En cours', const Color(0xFF1D4ED8));
      case 'ACCEPTE':
        return ('Accepté', const Color(0xFF059669));
      case 'REJETE':
        return ('Rejeté', const Color(0xFFDC2626));
      case 'CLOS':
        return ('Clôturé', const Color(0xFF6B7280));
      default:
        return ('En attente', const Color(0xFFD97706));
    }
  }

  void _showDossierDetail(BuildContext context, DossierModel dossier, Color primaryColor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DossierDetailSheet(dossier: dossier, primaryColor: primaryColor),
    );
  }
}

// ─── Badge statut ───────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ─── État vide ───────────────────────────────────────────────────────────────────
class _EmptyDossierState extends StatelessWidget {
  final Color primaryColor;
  final VoidCallback onCreateTap;

  const _EmptyDossierState({required this.primaryColor, required this.onCreateTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open_rounded, size: 72, color: primaryColor.withValues(alpha: 0.3)),
            const SizedBox(height: 20),
            const Text(
              'Aucun dossier en cours',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1E2432)),
            ),
            const SizedBox(height: 10),
            const Text(
              'Déposez votre premier dossier juridique pour le soumettre aux avocats qualifiés.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280), height: 1.5),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: onCreateTap,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                'Créer un dossier',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Erreur ───────────────────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 60, color: Color(0xFFD1D5DB)),
          const SizedBox(height: 16),
          const Text('Impossible de charger vos dossiers'),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    );
  }
}

// ─── Sheet création dossier ────────────────────────────────────────────────────
class _CreateDossierSheet extends ConsumerStatefulWidget {
  final Color primaryColor;
  final WidgetRef ref;

  const _CreateDossierSheet({required this.primaryColor, required this.ref});

  @override
  ConsumerState<_CreateDossierSheet> createState() => _CreateDossierSheetState();
}

class _CreateDossierSheetState extends ConsumerState<_CreateDossierSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titreController = TextEditingController();
  final _descController = TextEditingController();
  String _domaine = 'FAMILLE';
  bool _isLoading = false;

  static const _domaines = [
    ('FAMILLE', 'Famille & Mariage'),
    ('TRAVAIL', 'Droit du travail'),
    ('IMMOBILIER', 'Immobilier'),
    ('PENAL', 'Pénal'),
    ('COMMERCIAL', 'Commercial'),
    ('AUTRE', 'Autre'),
  ];

  @override
  void dispose() {
    _titreController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final ok = await ref.read(dossiersListProvider.notifier).createDossier(
          titre: _titreController.text.trim(),
          description: _descController.text.trim(),
          domaine: _domaine,
        );

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Dossier créé avec succès !' : 'Erreur lors de la création'),
          backgroundColor: ok ? const Color(0xFF059669) : Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottom),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Nouveau dossier juridique',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 20),

              // Titre
              const Text('Titre du dossier', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titreController,
                validator: (v) => (v?.isEmpty ?? true) ? 'Champ requis' : null,
                decoration: _inputDeco('Ex: Litige contrat de travail'),
              ),

              const SizedBox(height: 16),

              // Domaine juridique
              const Text('Domaine juridique', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _domaines.map(((String, String) d) {
                  final isSelected = _domaine == d.$1;
                  return GestureDetector(
                    onTap: () => setState(() => _domaine = d.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? widget.primaryColor : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? widget.primaryColor : const Color(0xFFE5E7EB),
                        ),
                      ),
                      child: Text(
                        d.$2,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : const Color(0xFF374151),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // Description
              const Text('Description du problème', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descController,
                maxLines: 4,
                validator: (v) => (v?.isEmpty ?? true) ? 'Décrivez votre situation' : null,
                decoration: _inputDeco('Décrivez votre situation en quelques lignes...'),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text(
                          'Soumettre le dossier',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: widget.primaryColor, width: 1.6)),
    );
  }
}

// ─── Sheet détail dossier ──────────────────────────────────────────────────────
class _DossierDetailSheet extends StatelessWidget {
  final DossierModel dossier;
  final Color primaryColor;

  const _DossierDetailSheet({required this.dossier, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: const Color(0xFFD1D5DB), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              dossier.titre,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
            ),
            const SizedBox(height: 8),
            if (dossier.reference.isNotEmpty)
              Text('#${dossier.reference}', style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
            const SizedBox(height: 16),
            if (dossier.description.isNotEmpty) ...[
              const Text('Description', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
              const SizedBox(height: 8),
              Text(dossier.description, style: const TextStyle(fontSize: 14, color: Color(0xFF374151), height: 1.5)),
              const SizedBox(height: 20),
            ],
            if (dossier.soumissions.isNotEmpty) ...[
              Text(
                'Propositions reçues (${dossier.soumissions.length})',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
              ),
              const SizedBox(height: 12),
              ...dossier.soumissions.map((s) => _SoumissionCard(soumission: s, primaryColor: primaryColor)),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.hourglass_empty_rounded, color: primaryColor, size: 24),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Votre dossier est en cours d\'analyse. Les avocats vous contacteront prochainement.',
                        style: TextStyle(fontSize: 13, color: Color(0xFF374151), height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SoumissionCard extends StatelessWidget {
  final SoumissionModel soumission;
  final Color primaryColor;

  const _SoumissionCard({required this.soumission, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            soumission.displayName,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
          ),
          if (soumission.reponse != null) ...[
            const SizedBox(height: 6),
            Text(soumission.reponse!, style: const TextStyle(fontSize: 13, color: Color(0xFF374151))),
          ],
          if (soumission.montantPropose != null) ...[
            const SizedBox(height: 8),
            Text(
              '${soumission.montantPropose!.toInt()} FCFA',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: primaryColor),
            ),
          ],
        ],
      ),
    );
  }
}
