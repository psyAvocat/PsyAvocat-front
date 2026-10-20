import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/realtime/realtime_service.dart';
import '../../../../core/theme/app_universe.dart';
import '../../../../core/theme/universe_provider.dart';
import '../../../auth/presentation/controllers/session_controller.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/notifications_repository.dart';

/// Toutes les notifications du compte, rechargées à chaque nouvel événement.
class NotificationsController extends AsyncNotifier<List<NotificationItem>> {
  @override
  Future<List<NotificationItem>> build() async {
    // Mode invité : aucune notification, aucun appel protégé.
    if (ref.watch(signedInAccountProvider) == null) return const [];
    listenRealtime(ref, {RealtimeEventType.notification}, (_) => _reload());
    return ref.read(notificationsRepositoryProvider).getNotifications();
  }

  Future<void> _reload() async {
    final result = await AsyncValue.guard(
      () => ref.read(notificationsRepositoryProvider).getNotifications(),
    );
    // En cas d'échec d'un rechargement silencieux, on garde la liste affichée.
    if (result.hasValue || !state.hasValue) state = result;
  }

  Future<void> refresh() async {
    await _reload();
  }

  /// Marque comme lue tout de suite à l'écran ; un échec réseau est sans
  /// conséquence (l'état serveur sera relu au prochain chargement).
  Future<void> markAsRead(String id) async {
    final current = state.value;
    if (current == null) return;
    final target = current.where((n) => n.id == id).firstOrNull;
    if (target == null || target.lu) return;
    state = AsyncData([
      for (final n in current) n.id == id ? n.markedRead() : n,
    ]);
    try {
      await ref.read(notificationsRepositoryProvider).markAsRead(id);
    } catch (_) {
      // Ignoré : simple indicateur de lecture.
    }
  }

  Future<void> markAllAsRead() async {
    final current = state.value;
    if (current == null) return;
    await ref.read(notificationsRepositoryProvider).markAllAsRead();
    state = AsyncData([for (final n in current) n.markedRead()]);
  }

  /// Retire la notification immédiatement (un élément balayé ne doit plus
  /// figurer dans la liste), puis la rétablit si le serveur refuse.
  Future<void> deleteNotification(String id) async {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.where((n) => n.id != id).toList());
    try {
      await ref.read(notificationsRepositoryProvider).deleteNotification(id);
    } catch (_) {
      state = AsyncData(current);
      rethrow;
    }
  }

  /// Supprime toutes les notifications lues (rétablies en cas d'échec).
  Future<void> deleteRead() async {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.where((n) => !n.lu).toList());
    try {
      await ref.read(notificationsRepositoryProvider).deleteRead();
    } catch (_) {
      state = AsyncData(current);
      rethrow;
    }
  }
}

/// Le contenu in-app est filtré par univers ; les notifications transverses
/// (sans univers) restent visibles partout.
bool isVisibleIn(NotificationItem n, AppUniverse universe) =>
    n.universe == null || n.universe == universe;

final notificationsControllerProvider =
    AsyncNotifierProvider<NotificationsController, List<NotificationItem>>(
      NotificationsController.new,
    );

/// Alias pour la compatibilité avec les écrans existants
final notificationsListProvider = notificationsControllerProvider;

/// Notifications de l'univers courant, les plus récentes d'abord.
final visibleNotificationsProvider =
    Provider<AsyncValue<List<NotificationItem>>>((ref) {
      final universe = ref.watch(currentUniverseProvider);
      return ref.watch(notificationsControllerProvider).whenData((items) {
        final visible = items.where((n) => isVisibleIn(n, universe)).toList()
          ..sort(
            (a, b) => (b.dateEnvoi ?? DateTime(0)).compareTo(
              a.dateEnvoi ?? DateTime(0),
            ),
          );
        return visible;
      });
    });

/// Badge de la cloche : non lues de l'univers courant (0 tant que non chargé).
final unreadNotificationsBadgeProvider = Provider<int>((ref) {
  final items = ref.watch(visibleNotificationsProvider).value ?? const [];
  return items.where((n) => !n.lu).length;
});
