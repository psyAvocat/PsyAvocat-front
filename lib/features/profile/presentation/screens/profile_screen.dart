import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/theme/universe_provider.dart';
import '../../../../core/theme/app_universe.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/controllers/session_controller.dart';
import '../../data/models/profil_model.dart';
import '../controllers/profil_controller.dart';
import '../../../rendez_vous/presentation/controllers/rendez_vous_controller.dart';
import '../../../dossiers/presentation/controllers/dossiers_controller.dart';

/// Écran « Mon profil » — données connectées à GET /api/profil et PUT /api/profil.
/// Respecte scrupuleusement la Clean Architecture et la charte graphique PsyAvocat.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final universe = ref.watch(currentUniverseProvider);
    final primaryColor = universe.primaryColor;
    final authState = ref.watch(authStateChangesProvider);
    final user = authState.asData?.value;
    final profilAsync = ref.watch(currentProfilProvider);
    final rdvAsync = ref.watch(rendezVousControllerProvider);
    final dossiersAsync = ref.watch(dossiersListProvider);

    final rdvCount = rdvAsync.value?.length ?? 0;
    final dossiersCount = dossiersAsync.value?.length ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(currentProfilProvider.notifier).refresh();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // ── AppBar avec Header dégradé et Avatar ─────────────────────────
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              backgroundColor: primaryColor,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: false,
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryColor,
                        primaryColor.withValues(alpha: 0.82),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: profilAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    error: (err, stack) => _ProfileAvatar(
                      email: user?.email,
                      name: null,
                      roleLabel: null,
                      primaryColor: primaryColor,
                    ),
                    data: (profil) => _ProfileAvatar(
                      email: user?.email,
                      name: profil?.displayName,
                      roleLabel: profil?.roleLabel,
                      primaryColor: primaryColor,
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit_rounded, color: Colors.white),
                  onPressed: () {
                    final current = profilAsync.value;
                    _showEditSheet(context, ref, current, primaryColor);
                  },
                  tooltip: 'Modifier mon profil',
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                  onPressed: () {
                    ref.read(currentProfilProvider.notifier).refresh();
                  },
                  tooltip: 'Actualiser',
                ),
              ],
            ),

            // ── Contenu du Profil ─────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // 1. Bandeau Statistiques rapides
                  _StatsRow(
                    rdvCount: rdvCount,
                    dossiersCount: dossiersCount,
                    universeLabel: universe.displayName,
                    universeColor: primaryColor,
                  ),

                  const SizedBox(height: 20),

                  // 2. Coordonnées & Informations du compte
                  profilAsync.when(
                    loading: () => const ContainerSkeleton(),
                    error: (err, stack) => _InfoCard(
                      items: [
                        _InfoRow(
                          Icons.email_outlined,
                          'Email',
                          user?.email ?? 'Non renseigné',
                        ),
                      ],
                    ),
                    data: (profil) => _InfoCard(
                      items: [
                        _InfoRow(
                          Icons.email_outlined,
                          'Email',
                          user?.email ?? 'Non renseigné',
                        ),
                        if (profil?.telephone != null && profil!.telephone!.isNotEmpty)
                          _InfoRow(
                            Icons.phone_outlined,
                            'Téléphone',
                            profil.telephone!,
                          ),
                        if (profil?.ville != null && profil!.ville!.isNotEmpty)
                          _InfoRow(
                            Icons.location_on_outlined,
                            'Ville',
                            ''!,
                          ),
                        _InfoRow(
                          Icons.badge_outlined,
                          'Statut du compte',
                          profil?.roleLabel ?? 'Utilisateur PsyAvocat',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 3. Bascule d'univers active
                  _SectionTitle('Univers d\'accompagnement'),
                  const SizedBox(height: 12),
                  _UniverseSelectorCard(
                    currentUniverse: universe,
                    onSelect: (newUni) {
                      ref.read(currentUniverseProvider.notifier).setUniverse(newUni);
                    },
                  ),

                  const SizedBox(height: 24),

                  // 4. Navigation rapide vers les fonctionnalités clés
                  _SectionTitle('Accès rapide'),
                  const SizedBox(height: 12),
                  _NavItem(
                    icon: Icons.calendar_month_rounded,
                    label: 'Mes rendez-vous',
                    subtitle: '$rdvCount consultation(s) enregistrée(s)',
                    color: primaryColor,
                    onTap: () => context.go('/rendez-vous'),
                  ),
                  _NavItem(
                    icon: Icons.folder_rounded,
                    label: 'Mes dossiers juridiques',
                    subtitle: '$dossiersCount dossier(s) en suivi',
                    color: const Color(0xFFD97706),
                    onTap: () => context.push('/dossiers'),
                  ),
                  _NavItem(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Messagerie & échanges',
                    subtitle: 'Discussions avec vos praticiens',
                    color: const Color(0xFF059669),
                    onTap: () => context.go('/messagerie'),
                  ),

                  const SizedBox(height: 24),

                  // 5. Paramètres & Sécurité
                  _SectionTitle('Sécurité & Assistance'),
                  const SizedBox(height: 12),
                  _NavItem(
                    icon: Icons.lock_outline_rounded,
                    label: 'Mot de passe & Sécurité',
                    subtitle: 'Gérer la sécurité de votre compte',
                    color: const Color(0xFF6366F1),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Un email de réinitialisation peut être envoyé depuis l\'écran de connexion.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                  _NavItem(
                    icon: Icons.help_outline_rounded,
                    label: 'Centre d\'aide & Support',
                    subtitle: 'FAQ et assistance technique',
                    color: const Color(0xFF6B7280),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Support PsyAvocat disponible 7j/7 par email : support@psyavocat.com'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // 6. Déconnexion
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmSignOut(context, ref),
                      icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                      label: const Text(
                        'Se déconnecter',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent, width: 1.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditSheet(
    BuildContext context,
    WidgetRef ref,
    ProfilModel? profil,
    Color primaryColor,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfilSheet(
        profil: profil,
        primaryColor: primaryColor,
        ref: ref,
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter de votre compte PsyAvocat ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Déconnexion', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldLogout == true && context.mounted) {
      await ref.read(sessionControllerProvider.notifier).signOut();
      if (context.mounted) {
        context.go('/login');
      }
    }
  }
}

// ─── En-tête Avatar & Titre ──────────────────────────────────────────────────
class _ProfileAvatar extends StatelessWidget {
  final String? email;
  final String? name;
  final String? roleLabel;
  final Color primaryColor;

  const _ProfileAvatar({
    this.email,
    this.name,
    this.roleLabel,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
            ),
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              child: const Icon(Icons.person_rounded, size: 46, color: Colors.white),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            name ?? email ?? 'Utilisateur',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              roleLabel ?? 'Membre PsyAvocat',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bandeau Statistiques ────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final int rdvCount;
  final int dossiersCount;
  final String universeLabel;
  final Color universeColor;

  const _StatsRow({
    required this.rdvCount,
    required this.dossiersCount,
    required this.universeLabel,
    required this.universeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(count: '$rdvCount', label: 'Rendez-vous'),
          Container(height: 32, width: 1, color: const Color(0xFFE5E7EB)),
          _StatItem(count: '$dossiersCount', label: 'Dossiers'),
          Container(height: 32, width: 1, color: const Color(0xFFE5E7EB)),
          _StatItem(
            count: universeLabel,
            label: 'Univers actif',
            countColor: universeColor,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String count;
  final String label;
  final Color? countColor;

  const _StatItem({
    required this.count,
    required this.label,
    this.countColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: countColor ?? const Color(0xFF1E2432),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─── Carte d'informations ────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final List<Widget> items;
  const _InfoCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final isLast = e.key == items.length - 1;
          return Column(
            children: [
              e.value,
              if (!isLast) const Divider(height: 20, color: Color(0xFFF3F4F6)),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF6B7280)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E2432),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Sélecteur Univers ───────────────────────────────────────────────────────
class _UniverseSelectorCard extends StatelessWidget {
  final AppUniverse currentUniverse;
  final ValueChanged<AppUniverse> onSelect;

  const _UniverseSelectorCard({
    required this.currentUniverse,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _UniverseButton(
              title: 'Avocat',
              subtitle: 'Juridique',
              icon: Icons.gavel_rounded,
              color: const Color(0xFF1E3A8A),
              isSelected: currentUniverse.isLawyer,
              onTap: () => onSelect(AppUniverse.lawyer),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _UniverseButton(
              title: 'Psychologue',
              subtitle: 'Santé mentale',
              icon: Icons.psychology_rounded,
              color: const Color(0xFF0F766E),
              isSelected: currentUniverse.isPsychologist,
              onTap: () => onSelect(AppUniverse.psychologist),
            ),
          ),
        ],
      ),
    );
  }
}

class _UniverseButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _UniverseButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.12) : const Color(0xFFF9FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: isSelected ? color : const Color(0xFF6B7280)),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? color : const Color(0xFF374151),
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Titre de section ────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: Color(0xFF1E2432),
        ),
      );
}

// ─── Item de navigation ──────────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E2432),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFD1D5DB)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Skeleton de chargement ──────────────────────────────────────────────────
class ContainerSkeleton extends StatelessWidget {
  const ContainerSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

// ─── Sheet édition du profil ─────────────────────────────────────────────────
class _EditProfilSheet extends ConsumerStatefulWidget {
  final ProfilModel? profil;
  final Color primaryColor;
  final WidgetRef ref;

  const _EditProfilSheet({
    this.profil,
    required this.primaryColor,
    required this.ref,
  });

  @override
  ConsumerState<_EditProfilSheet> createState() => _EditProfilSheetState();
}

class _EditProfilSheetState extends ConsumerState<_EditProfilSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _prenomController;
  late final TextEditingController _nomController;
  late final TextEditingController _telephoneController;
  late final TextEditingController _villeController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final p = widget.profil;
    _prenomController = TextEditingController(text: p?.prenom ?? '');
    _nomController = TextEditingController(text: p?.nom ?? '');
    _telephoneController = TextEditingController(text: p?.telephone ?? '');
    _villeController = TextEditingController(text: p?.ville ?? '');
  }

  @override
  void dispose() {
    _prenomController.dispose();
    _nomController.dispose();
    _telephoneController.dispose();
    _villeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final ok = await ref.read(currentProfilProvider.notifier).updateProfile(
          prenom: _prenomController.text.trim(),
          nom: _nomController.text.trim(),
          telephone: _telephoneController.text.trim().isNotEmpty
              ? _telephoneController.text.trim()
              : null,

        );

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok ? 'Profil mis à jour avec succès !' : 'Erreur lors de la mise à jour du profil.',
          ),
          backgroundColor: ok ? const Color(0xFF059669) : Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Modifier mes coordonnées',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E2432),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _prenomController,
                    decoration: InputDecoration(
                      labelText: 'Prénom',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _nomController,
                    decoration: InputDecoration(
                      labelText: 'Nom',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _telephoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Numéro de téléphone',
                hintText: '+221 77 000 00 00',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _villeController,
              decoration: InputDecoration(
                labelText: 'Ville de résidence',
                hintText: 'Dakar',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Enregistrer les modifications',
                        style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
