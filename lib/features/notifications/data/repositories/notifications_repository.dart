import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_providers.dart';
import '../models/notification_model.dart';

/// Contrat du repository de notifications
abstract class NotificationsRepository {
  Future<List<NotificationModel>> getNotifications();
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();
  Future<void> deleteNotification(String id);
}

/// Implémentation API connectée au backend Spring Boot (GET /api/notifications)
class ApiNotificationsRepository implements NotificationsRepository {
  final ApiClient _client;

  ApiNotificationsRepository(this._client);

  @override
  Future<List<NotificationModel>> getNotifications() async {
    try {
      final response = await _client.get('/notifications');
      final list = response.data as List<dynamic>? ?? [];
      return list
          .map((item) => NotificationModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Si l'endpoint n'est pas encore implémenté ou renvoie 404, renvoie une liste vide
      return [];
    }
  }

  @override
  Future<void> markAsRead(String id) async {
    try {
      await _client.put('/notifications/$id/read');
    } catch (_) {}
  }

  @override
  Future<void> markAllAsRead() async {
    try {
      await _client.put('/notifications/read-all');
    } catch (_) {}
  }

  @override
  Future<void> deleteNotification(String id) async {
    try {
      await _client.delete('/notifications/$id');
    } catch (_) {}
  }
}

/// Provider officiel pour l'accès aux notifications réelles
final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return ApiNotificationsRepository(client);
});
