import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/theme/universe_provider.dart';
import '../../../profile/presentation/controllers/profil_controller.dart';
import '../../../rendez_vous/data/models/rendez_vous_model.dart';
import '../../../rendez_vous/presentation/controllers/rendez_vous_controller.dart';
import '../../../dossiers/presentation/controllers/dossiers_controller.dart';
import '../../../notifications/presentation/controllers/notifications_controller.dart';
import '../../../professionnels/presentation/controllers/professionnels_controller.dart';
import '../../../professionnels/data/models/professional_detail_model.dart';
import '../../../contenus/presentation/controllers/contenus_controller.dart';
import '../../../contenus/data/models/contenu_model.dart';

/// Tableau de bord officiel PsyAvocat — Conforme à la charte et aux exigences métier.
/// Architecture : Flutter (Présentation + État UI) -> Repositories API -> Spring Boot -> MySQL.
/// Aucune donnée métier hardcodée.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final universe = ref.watch(currentUniverseProvider);
    final primaryColor = universe.primaryColor;
    final isAvocat = universe.isLawyer || universe.isNeutral;

    final authState = ref.watch(authStateChangesProvider);
    final user = authState.asData?.value;
    final profilAsync = ref.watch(currentProfilProvider);
    final rdvAsync = ref.watch(rendezVousListProvider);
    final dossiersAsync = ref.watch(dossiersListProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final prosAsync = ref.watch(professionnelsListProvider(isAvocat));
    final contenusAsync = ref.watch(contenusListProvider);

    // Salutation dynamique
    final greeting = _getGreeting();
    final prenom = profilAsync.value?.prenom;
    final displayName = (prenom != null && prenom.isNotEmpty)
        ? prenom
        : (user?.displayName?.split(' ').first ?? '');

    // Prochain rendez-vous réel
    final List<RendezVousItem> allRdv = rdvAsync.value ?? [];
    final RendezVousItem? nextRdv = allRdv
        .where((r) => r.status == 'Confirmé' || r.status == 'En attente')
        .firstOrNull;

    final int rdvCount = allRdv.length;
    final int dossiersCount = dossiersAsync.value?.length ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ─── A. APP BAR / HEADER MODERNE ────────────────────────────────
            SliverAppBar(
              floating: true,
              pinned: true,
              elevation: 0,
              backgroundColor: Colors.white,
              toolbarHeight: 70,
              title: Row(
                children: [
                  // Logo réel depuis assets
                  Image.asset(
                    'assets/logos/logo_psyavocat.png',
                    height: 38,
                    width: 38,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isAvocat ? Icons.gavel_rounded : Icons.psychology_rounded,
                        color: primaryColor,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'PsyAvocat',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E2432),
                          fontFamily: 'Montserrat',
                          letterSpacing: -0.4,
                        ),
                      ),
                      Text(
                        'Bien-être • Conseil • Droits',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                // Bouton Notifications avec badge dynamique réel
                Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.notifications_none_rounded,
                        color: Color(0xFF1E2432),
                        size: 26,
                      ),
                      tooltip: 'Notifications',
                      onPressed: () => context.push('/notifications'),
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 8,
                        top: 12,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFB1216), // Danger color
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                          child: Center(
                            child: Text(
                              unreadCount > 9 ? '9+' : '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                // Profil / Avatar
                Padding(
                  padding: const EdgeInsets.only(right: 16.0, left: 4.0),
                  child: InkWell(
                    onTap: () => context.go('/profil'),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(color: primaryColor.withValues(alpha: 0.25), width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ─── CONTENU DU TABLEAU DE BORD ──────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // B. SALUTATION PERSONNALISÉE
                  _buildSalutation(greeting, displayName),
                  const SizedBox(height: 16),

                  // C. IDENTITÉ DE L'UNIVERS
                  _buildUniverseIdentityCard(context, universe, primaryColor),
                  const SizedBox(height: 20),

                  // D. BLOC D'AIDE PRINCIPAL (HERO / CTA)
                  _buildMainHeroCard(context, universe, primaryColor),
                  const SizedBox(height: 20),

                  // E. BLOC DE RECHERCHE
                  _buildSearchCard(context, isAvocat),
                  const SizedBox(height: 24),

                  // F. PROCHAIN RENDEZ-VOUS (RÉEL OU EMPTY STATE)
                  _buildUpcomingAppointmentSection(context, nextRdv, primaryColor),
                  const SizedBox(height: 28),

                  // G. ACCÈS RAPIDES
                  _buildQuickAccessSection(context, universe, rdvCount, dossiersCount),
                  const SizedBox(height: 28),

                  // H. PROFESSIONNELS RECOMMANDÉS (API MYSQL)
                  _buildRecommendedProsSection(context, prosAsync, isAvocat, primaryColor),
                  const SizedBox(height: 28),

                  // I. CONTENUS / CONSEILS À DÉCOUVRIR (API)
                  _buildFeaturedContentSection(context, contenusAsync, primaryColor),
                  const SizedBox(height: 28),

                  // J. INFORMATIONS UTILES & SÉCURITÉ
                  _buildHelpAndSecuritySection(primaryColor),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Salutation selon l'heure
  // ────────────────────────────────────────────────────────────────────────────
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bonjour';
    if (hour < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }

  Widget _buildSalutation(String greeting, String displayName) {
    final text = displayName.isNotEmpty ? '$greeting, $displayName 👋' : '$greeting 👋';
    return Text(
      text,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: Color(0xFF1E2432),
        fontFamily: 'Montserrat',
        letterSpacing: -0.4,
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // C. Carte Identité de l'Univers
  // ────────────────────────────────────────────────────────────────────────────
  Widget _buildUniverseIdentityCard(BuildContext context, dynamic universe, Color primaryColor) {
    final bool isPsy = universe.isPsychologist as bool;
    final String label = isPsy ? 'Psychologie' : 'Conseil juridique';
    final String subtitle = isPsy
        ? 'Santé mentale & soutien thérapeutique'
        : 'Assistance légale & défense de vos droits';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primaryColor.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPsy ? Icons.psychology_rounded : Icons.gavel_rounded,
              color: primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: primaryColor,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Actif',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.push('/selection-univers'),
            style: TextButton.styleFrom(
              foregroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Changer',
                  style: TextStyle(fontWeight: FontWeight.w700, color: primaryColor, fontSize: 13),
                ),
                const SizedBox(width: 4),
                Icon(Icons.swap_horiz_rounded, size: 16, color: primaryColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // D. Bloc d'aide principal (Hero / CTA)
  // ────────────────────────────────────────────────────────────────────────────
  Widget _buildMainHeroCard(BuildContext context, dynamic universe, Color primaryColor) {
    final bool isPsy = universe.isPsychologist as bool;
    final String situationText = isPsy
        ? 'Vous cherchez un accompagnement adapté ?'
        : 'Vous cherchez un avocat pour votre situation ?';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Comment pouvons-nous vous aider aujourd\'hui ?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              fontFamily: 'Montserrat',
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            situationText,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // CTA 1 : Trouver un professionnel
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/professionnels'),
                  icon: Icon(
                    isPsy ? Icons.psychology_rounded : Icons.gavel_rounded,
                    size: 16,
                    color: primaryColor,
                  ),
                  label: const Text(
                    'Professionnels',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // CTA 2 : Questionnaire d'orientation
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/orientation'),
                  icon: const Icon(
                    Icons.auto_awesome_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Orientation',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // E. Bloc de recherche
  // ────────────────────────────────────────────────────────────────────────────
  Widget _buildSearchCard(BuildContext context, bool isAvocat) {
    return InkWell(
      onTap: () => context.go('/professionnels'),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: const [
            Icon(Icons.search_rounded, color: Color(0xFF9CA3AF), size: 22),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Rechercher un avocat ou un psychologue...',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.tune_rounded, color: Color(0xFF6B7280), size: 20),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // F. Prochain Rendez-vous
  // ────────────────────────────────────────────────────────────────────────────
  Widget _buildUpcomingAppointmentSection(
    BuildContext context,
    RendezVousItem? rdv,
    Color primaryColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Votre prochain rendez-vous',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E2432),
                fontFamily: 'Montserrat',
              ),
            ),
            if (rdv != null)
              TextButton(
                onPressed: () => context.go('/rendez-vous'),
                child: Text(
                  'Voir tout',
                  style: TextStyle(color: primaryColor, fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (rdv == null)
          // EmptyState propre
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.event_available_outlined,
                  size: 40,
                  color: primaryColor.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Vous n\'avez pas encore de rendez-vous',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E2432),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Consultez nos praticiens disponibles pour réserver une séance.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: () => context.go('/professionnels'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: const Text(
                    'Trouver un professionnel',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ],
            ),
          )
        else
          // Carte rendez-vous réel
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primaryColor.withValues(alpha: 0.3), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            rdv.status,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          rdv.mode,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                    if (rdv.montantTotal > 0)
                      Text(
                        '${rdv.montantTotal} FCFA',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E2432),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  rdv.proName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E2432),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 15, color: Color(0xFF6B7280)),
                    const SizedBox(width: 6),
                    Text(
                      '${rdv.day} ${rdv.month} ${rdv.year} à ${rdv.time}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => context.go('/rendez-vous'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryColor,
                      side: BorderSide(color: primaryColor, width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'Voir le rendez-vous',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // G. Accès Rapides (6 cartes modernes)
  // ────────────────────────────────────────────────────────────────────────────
  Widget _buildQuickAccessSection(
    BuildContext context,
    dynamic universe,
    int rdvCount,
    int dossiersCount,
  ) {
    final bool isPsy = universe.isPsychologist as bool;
    final primaryColor = universe.primaryColor as Color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Accès rapides',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E2432),
            fontFamily: 'Montserrat',
          ),
        ),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 1.35,
          children: [
            _QuickActionTile(
              icon: isPsy ? Icons.psychology_rounded : Icons.gavel_rounded,
              title: 'Professionnels',
              subtitle: 'Annuaire certifié',
              color: primaryColor,
              onTap: () => context.go('/professionnels'),
            ),
            _QuickActionTile(
              icon: Icons.calendar_month_rounded,
              title: 'Rendez-vous',
              subtitle: rdvCount > 0 ? '$rdvCount prévu(s)' : 'Consulter',
              color: const Color(0xFF4BD418), // Success color
              onTap: () => context.go('/rendez-vous'),
            ),
            _QuickActionTile(
              icon: Icons.folder_rounded,
              title: 'Mes dossiers',
              subtitle: dossiersCount > 0 ? '$dossiersCount actif(s)' : 'Suivi juridique',
              color: const Color(0xFFF2C121), // Warning color
              onTap: () => context.go('/dossiers'),
            ),
            _QuickActionTile(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Messagerie',
              subtitle: 'Échanges praticiens',
              color: const Color(0xFF6366F1),
              onTap: () => context.push('/messagerie'),
            ),
            _QuickActionTile(
              icon: Icons.menu_book_rounded,
              title: 'Contenus',
              subtitle: 'Guides & Articles',
              color: const Color(0xFF0284C7),
              onTap: () => context.push('/contenus'),
            ),
            _QuickActionTile(
              icon: isPsy ? Icons.mood_rounded : Icons.account_circle_outlined,
              title: isPsy ? 'Suivi bien-être' : 'Mon profil',
              subtitle: isPsy ? 'Journal d\'humeur' : 'Mes informations',
              color: isPsy ? const Color(0xFFE11D48) : primaryColor,
              onTap: () {
                if (isPsy) {
                  context.push('/suivi-psychologique');
                } else {
                  context.go('/profil');
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // H. Professionnels Recommandés (API Spring Boot / MySQL)
  // ────────────────────────────────────────────────────────────────────────────
  Widget _buildRecommendedProsSection(
    BuildContext context,
    AsyncValue<List<ProfessionalDetail>> prosAsync,
    bool isAvocat,
    Color primaryColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isAvocat ? 'Avocats recommandés' : 'Psychologues recommandés',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E2432),
                fontFamily: 'Montserrat',
              ),
            ),
            TextButton(
              onPressed: () => context.go('/professionnels'),
              child: Text(
                'Voir tout',
                style: TextStyle(color: primaryColor, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        prosAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (_, _) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: const Center(
              child: Text(
                'Impossible de charger les praticiens',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
            ),
          ),
          data: (pros) {
            if (pros.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Center(
                  child: Text(
                    isAvocat
                        ? 'Aucun avocat disponible actuellement.'
                        : 'Aucun psychologue disponible actuellement.',
                    style: const TextStyle(color: Color(0xFF6B7280)),
                  ),
                ),
              );
            }

            final topPros = pros.take(3).toList();
            return Column(
              children: topPros.map((pro) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: InkWell(
                    onTap: () => context.push('/professionnels/${pro.id}'),
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              isAvocat ? Icons.gavel_rounded : Icons.psychology_rounded,
                              color: primaryColor,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pro.nom,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  pro.specialitePrincipale,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                                if (pro.ville.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    pro.ville,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF9CA3AF),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (pro.tarifs.isNotEmpty)
                            Text(
                              pro.tarifs.first.formattedPrice,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: primaryColor,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // I. Contenus / Conseils à découvrir (API Spring Boot / MySQL)
  // ────────────────────────────────────────────────────────────────────────────
  Widget _buildFeaturedContentSection(
    BuildContext context,
    AsyncValue<List<ContenuModel>> contenusAsync,
    Color primaryColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'À découvrir',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E2432),
                fontFamily: 'Montserrat',
              ),
            ),
            TextButton(
              onPressed: () => context.push('/contenus'),
              child: Text(
                'Voir tout',
                style: TextStyle(color: primaryColor, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        contenusAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (_, _) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: const Center(
              child: Text(
                'Aucun article disponible pour le moment',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
            ),
          ),
          data: (articles) {
            if (articles.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: const Center(
                  child: Text(
                    'Aucun article publié pour le moment. Revenez bientôt !',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                  ),
                ),
              );
            }

            final first = articles.first;
            return InkWell(
              onTap: () => context.push('/contenus/${first.id}'),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.article_rounded, color: primaryColor, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (first.categorie.isNotEmpty)
                            Text(
                              first.categorie.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: primaryColor,
                              ),
                            ),
                          const SizedBox(height: 3),
                          Text(
                            first.titre,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E2432),
                            ),
                          ),
                          if (first.dureeLecture.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              first.dureeLecture,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF9CA3AF)),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // J. Informations Utiles & Sécurité (Textes institutionnels UI)
  // ────────────────────────────────────────────────────────────────────────────
  Widget _buildHelpAndSecuritySection(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, color: primaryColor, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Plateforme sécurisée & confidentielle',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E2432),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'PsyAvocat applique le secret professionnel absolu des avocats et le code de déontologie des psychologues. Vos dossiers et vos échanges sont chiffrés de bout en bout.',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF475569),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Widget Tuile d'action rapide
// ────────────────────────────────────────────────────────────────────────────
class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E2432),
              ),
            ),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
