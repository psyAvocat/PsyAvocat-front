import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/data/repositories/session_repository.dart';
import '../../../auth/presentation/controllers/session_controller.dart';
import '../../../notifications/presentation/controllers/notifications_controller.dart';
import '../../../profile/presentation/controllers/profil_controller.dart';
import '../../../../core/l10n/app_strings.dart';

/// Haut de l'accueil (maquettes « Accueil ») : photo de l'utilisateur à gauche,
/// notifications à droite. Le changement d'univers est dans le profil.
class HomeTopBar extends ConsumerWidget {
  const HomeTopBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationsBadgeProvider);
    // Identité chargée uniquement pour une session ouverte.
    final connecte = ref.watch(signedInAccountProvider) != null;
    final user = connecte ? ref.watch(currentUserProvider).value : null;
    final photoUrl = ref.watch(currentProfilProvider).value?.photoUrl;
    final name = '${user?.prenom ?? ''} ${user?.nom ?? ''}'.trim();

    return Row(
      children: [
        InkWell(
          customBorder: const CircleBorder(),
          onTap: () => context.go(AppRoutes.profil),
          child: AppAvatar(
            name: name.isEmpty ? 'Moi' : name,
            photoUrl: photoUrl,
            size: 48,
          ),
        ),
        const Spacer(),
        IconButton(
          tooltip: tr('Notifications'),
          onPressed: () => context.push(AppRoutes.notifications),
          icon: Badge(
            isLabelVisible: unreadCount > 0,
            label: Text('$unreadCount'),
            child: const Icon(Icons.notifications_outlined),
          ),
        ),
      ],
    );
  }
}
