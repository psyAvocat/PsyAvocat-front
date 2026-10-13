import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';
import '../network/network_providers.dart';

/// Enregistrement des appareils FCM du compte (`/api/devices`).
abstract class DeviceRepository {
  /// [plateforme] : ANDROID, IOS ou WEB.
  Future<void> register({required String token, required String plateforme});

  Future<void> unregister(String token);
}

class ApiDeviceRepository implements DeviceRepository {
  final ApiClient _client;

  ApiDeviceRepository(this._client);

  @override
  Future<void> register({
    required String token,
    required String plateforme,
  }) async {
    await _client.post(
      '/devices',
      data: {'token': token, 'plateforme': plateforme},
    );
  }

  @override
  Future<void> unregister(String token) async {
    await _client.delete('/devices', queryParameters: {'token': token});
  }
}

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  return ApiDeviceRepository(ref.watch(apiClientProvider));
});
