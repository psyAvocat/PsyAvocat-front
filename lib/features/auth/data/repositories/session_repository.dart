import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_providers.dart';
import '../models/current_user.dart';

/// Session côté backend : qui est connecté et avec quel rôle.
abstract class SessionRepository {
  /// `GET /me` — nécessite un token Firebase (ajouté par l'AuthInterceptor).
  Future<CurrentUser> getCurrentUser();
}

class ApiSessionRepository implements SessionRepository {
  final ApiClient _client;

  ApiSessionRepository(this._client);

  @override
  Future<CurrentUser> getCurrentUser() async {
    // /me est exposé à la racine du serveur, pas sous /api : URL complète.
    final response = await _client.get(AppConfig.meUrl);
    return CurrentUser.fromJson(response.data as Map<String, dynamic>);
  }
}

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return ApiSessionRepository(ref.watch(apiClientProvider));
});

/// Utilisateur connecté (rechargé via `ref.invalidate(currentUserProvider)`).
final currentUserProvider = FutureProvider<CurrentUser>((ref) {
  return ref.watch(sessionRepositoryProvider).getCurrentUser();
});
