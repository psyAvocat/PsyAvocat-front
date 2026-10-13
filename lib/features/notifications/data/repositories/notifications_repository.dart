import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_providers.dart';
import '../models/notification_model.dart';

abstract class NotificationsRepository {
  Future<List<NotificationItem>> getNotifications();

  /// Nombre de notifications non lues (le backend renvoie un nombre brut).
  Future<int> getUnreadCount();

  Future<void> markAsRead(String id);

  Future<void> markAllAsRead();

  Future<void> deleteNotification(String id);
}

class ApiNotificationsRepository implements NotificationsRepository {
  final ApiClient _client;

  ApiNotificationsRepository(this._client);

  @override
  Future<List<NotificationItem>> getNotifications() async {
    final response = await _client.get('/notifications');
    final list = response.data as List<dynamic>? ?? [];
    return list
        .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<int> getUnreadCount() async {
    final response = await _client.get('/notifications/unread-count');
    return (response.data as num?)?.toInt() ?? 0;
  }

  @override
  Future<void> markAsRead(String id) => _client.patch('/notifications/$id/lu');

  @override
  Future<void> markAllAsRead() => _client.patch('/notifications/lu-tout');

  @override
  Future<void> deleteNotification(String id) =>
      _client.delete('/notifications/$id');
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>((
  ref,
) {
  return ApiNotificationsRepository(ref.watch(apiClientProvider));
});
