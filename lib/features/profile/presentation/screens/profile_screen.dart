import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/theme/universe_provider.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../auth/presentation/controllers/session_controller.dart';
import '../controllers/profil_controller.dart';
import '../widgets/profile_menu.dart';
import '../../../../core/l10n/app_strings.dart';

/// « Mon profil » — maquettes « Profil utilisateur » (Avocat et Psychologue) :
/// carte d'identité, menu, puis déconnexion.
///
/// L'entrée propre à l'univers change : « Mes dossiers » (Avocat) ou
/// « Fiche patient » (Psychologue).
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final universe = ref.watch(currentUniverseProvider);
    final profil = ref.watch(currentProfilProvider).value;
    final session = ref.watch(sessionControllerProvider).user;
    final nom = profil?.nomComplet.isNotEmpty == true
        ? profil!.nomComplet
        : '${session?.prenom ?? ''} ${session?.nom ?? ''}'.trim();
    final email = profil?.email.isNotEmpty == true
        ? profil!.email
        : (session?.email ?? '');

    final palette = context.palette;
    // Titre fixe dans la barre : seul le contenu défile.
    return Scaffold(
      backgroundColor: palette.card,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: palette.card,
        title: Text(
          tr('Mon profil'),
          style: AppTypography.petitTitre.copyWith(color: palette.textStrong),
        ),
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            // Marge basse : la barre de navigation flotte au-dessus.
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 128,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppSpacing.vGap24,
                    _CarteIdentite(
                      nom: nom.isEmpty ? tr('Mon compte') : nom,
                      email: email,
                      photoUrl: profil?.photoUrl,
                    ),
                    AppSpacing.vGap24,
                    ProfileMenuItem(
                      icon: Icons.badge_outlined,
                      label: tr('Informations personnelles'),
                      onTap: () =>
                          context.push(AppRoutes.informationsPersonnelles),
                    ),
                    if (universe.isPsychologist)
                      ProfileMenuItem(
                        icon: Icons.inbox_outlined,
                        label: tr('Fiche patient'),
                        onTap: () => context.push(AppRoutes.fichePatient),
                      )
                    else
                      ProfileMenuItem(
                        icon: Icons.inbox_outlined,
                        label: tr('Mes dossiers'),
                        onTap: () => context.push(AppRoutes.dossiers),
                      ),
                    ProfileMenuItem(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: tr('Messagerie'),
                      onTap: () => context.push(AppRoutes.messagerie),
                    ),
                    ProfileMenuItem(
                      icon: Icons.help_outline_rounded,
                      label: tr('Aide et support'),
                      onTap: () => context.push(AppRoutes.aideSupport),
                    ),
                    ProfileMenuItem(
                      icon: Icons.settings_outlined,
                      label: tr('Paramètres'),
                      onTap: () => context.push(AppRoutes.parametres),
                    ),
                    const Spacer(),
                    AppSpacing.vGap40,
                    SizedBox(
                      height: 46,
                      child: OutlinedButton(
                        onPressed: () => _confirmSignOut(context, ref),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          side: const BorderSide(color: AppColors.danger),
                          shape: const StadiumBorder(),
                          padding: EdgeInsets.zero,
                          textStyle: AppTypography.texteSemiBold.copyWith(
                            fontSize: 16,
                            height: 1.2,
                          ),
                        ),
                        child: Text(tr('Se déconnecter')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(tr('Déconnexion')),
        content: Text(
          tr(
            'Êtes-vous sûr de vouloir vous déconnecter de votre compte PsyAvocat ?',
          ),
        ),
        actions: [
          AppButton.ghost(
            text: tr('Annuler'),
            color: context.palette.textMuted,
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          AppButton(
            text: tr('Déconnexion'),
            color: AppColors.danger,
            isFullWidth: false,
            size: AppButtonSize.compact,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (shouldLogout == true && context.mounted) {
      // Le routeur renvoie vers la connexion dès que la session est fermée.
      await ref.read(sessionControllerProvider.notifier).signOut();
    }
  }
}

class _CarteIdentite extends StatelessWidget {
  final String nom;
  final String email;
  final String? photoUrl;

  const _CarteIdentite({required this.nom, required this.email, this.photoUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.palette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.palette.border),
      ),
      child: Row(
        children: [
          AppAvatar(name: nom, photoUrl: photoUrl, size: 64),
          AppSpacing.hGap16,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nom,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.petitTitre.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.palette.textStrong,
                  ),
                ),
                if (email.isNotEmpty) ...[
                  AppSpacing.vGap4,
                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.texteSecondaire.copyWith(
                      color: context.palette.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
