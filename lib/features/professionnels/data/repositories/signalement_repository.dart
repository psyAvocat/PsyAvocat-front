import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_providers.dart';

/// Motif de signalement proposé par le backend (code + libellé affichable).
class MotifSignalement {
  final String code;
  final String libelle;

  const MotifSignalement({required this.code, required this.libelle});

  factory MotifSignalement.fromJson(Map<String, dynamic> json) {
    return MotifSignalement(
      code: json['code'] as String? ?? '',
      libelle: json['libelle'] as String? ?? '',
    );
  }

  /// Le motif « Autre » exige une description détaillée (10 caractères min.).
  bool get requiresDescription => code == 'AUTRE';
}

/// Signalement d'un professionnel par un client (`/api/signalements`).
abstract class SignalementRepository {
  Future<List<MotifSignalement>> getMotifs();

  Future<void> signaler({
    required String professionnelId,
    required String motif,
    String? description,
  });
}

class ApiSignalementRepository implements SignalementRepository {
  final ApiClient _client;

  ApiSignalementRepository(this._client);

  @override
  Future<List<MotifSignalement>> getMotifs() async {
    final response = await _client.get('/signalements/motifs');
    final list = response.data as List<dynamic>? ?? [];
    return list.map((e) => MotifSignalement.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> signaler({
    required String professionnelId,
    required String motif,
    String? description,
  }) async {
    await _client.post(
      '/signalements',
      data: {
        'professionnelId': professionnelId,
        'motif': motif,
        if (description != null && description.trim().isNotEmpty) 'description': description.trim(),
      },
    );
  }
}

final signalementRepositoryProvider = Provider<SignalementRepository>((ref) {
  return ApiSignalementRepository(ref.watch(apiClientProvider));
});
