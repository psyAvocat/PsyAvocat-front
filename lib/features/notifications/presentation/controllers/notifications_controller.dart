import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/notifications_repository.dart';

/// Provider pour la liste complète des notifications de l'utilisateur connecté
final notificationsListProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<NotificationModel>>(
  NotificationsNotifier.new,
);

/// Provider dynamique calculant le nombre réel de notifications non lues depuis l'API
final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifsAsync = ref.watch(notificationsListProvider);
  return notifsAsync.maybeWhen(
    data: (list) => list.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});

class NotificationsNotifier extends AsyncNotifier<List<NotificationModel>> {
  @override
  Future<List<NotificationModel>> build() async {
    return ref.read(notificationsRepositoryProvider).getNotifications();
  }

  Future<void> markAsRead(String id) async {
    await ref.read(notificationsRepositoryProvider).markAsRead(id);
    final current = state.value ?? [];
    state = AsyncData(
      current.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList(),
    );
  }

  Future<void> markAllAsRead() async {
    await ref.read(notificationsRepositoryProvider).markAllAsRead();
    final current = state.value ?? [];
    state = AsyncData(
      current.map((n) => n.copyWith(isRead: true)).toList(),
    );
  }

  Future<void> deleteNotification(String id) async {
    await ref.read(notificationsRepositoryProvider).deleteNotification(id);
    final current = state.value ?? [];
    state = AsyncData(
      current.where((n) => n.id != id).toList(),
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(notificationsRepositoryProvider).getNotifications(),
    );
  }
}
