import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/theme/universe_provider.dart';
import '../../../auth/data/repositories/session_repository.dart';
import '../../../notifications/presentation/controllers/notifications_controller.dart';

/// En-tête de l'accueil : salutation, notifications et univers actif.
class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final universe = ref.watch(currentUniverseProvider);
    final unreadCount = ref.watch(unreadNotificationsBadgeProvider);

    // Le prénom vient du backend (GET /me) ; tant qu'il n'est pas connu : « Bonjour ».
    final prenom = ref.watch(currentUserProvider).value?.prenom?.trim() ?? '';
    final greeting = prenom.isEmpty ? 'Bonjour' : 'Bonjour $prenom';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                greeting,
                style: AppTypography.titreMoyen,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              tooltip: 'Notifications',
              onPressed: () => context.push('/notifications'),
              icon: Badge(
                isLabelVisible: unreadCount > 0,
                label: Text('$unreadCount'),
                child: const Icon(Icons.notifications_outlined),
              ),
            ),
          ],
        ),
        AppSpacing.vGap4,
        Text(
          'Comment pouvons-nous vous aider aujourd’hui ?',
          style: AppTypography.texteSecondaire,
        ),
        AppSpacing.vGap16,
        ActionChip(
          avatar: Icon(
            universe.isPsychologist
                ? Icons.psychology_outlined
                : Icons.balance_outlined,
            size: AppIcons.sizeSm,
            color: scheme.primary,
          ),
          label: Text('Univers ${universe.displayName} · Changer'),
          onPressed: () => context.push('/selection-univers'),
        ),
      ],
    );
  }
}
