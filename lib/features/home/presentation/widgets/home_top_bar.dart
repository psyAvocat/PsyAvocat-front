import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/universe_provider.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/data/repositories/session_repository.dart';
import '../../../notifications/presentation/controllers/notifications_controller.dart';
import '../../../profile/presentation/controllers/profil_controller.dart';
import '../../../selection_univers/presentation/widgets/universe_switch_dialog.dart';

/// Haut de l'accueil (maquettes « Accueil ») : photo de l'utilisateur à gauche,
/// changement d'univers et notifications à droite.
class HomeTopBar extends ConsumerWidget {
  const HomeTopBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final universe = ref.watch(currentUniverseProvider);
    final unreadCount = ref.watch(unreadNotificationsBadgeProvider);
    final user = ref.watch(currentUserProvider).value;
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
          tooltip: universe.isPsychologist
              ? 'Passer à l’espace Avocat'
              : 'Passer à l’espace Psychologue',
          onPressed: () => confirmUniverseSwitch(context, ref),
          icon: const Icon(Icons.swap_horiz_rounded),
        ),
        IconButton(
          tooltip: 'Notifications',
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
