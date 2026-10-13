import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/network_providers.dart';

/// Motif de signalement (liste contrôlée par le backend : jamais définie dans l'application).
class MotifSignalement {
  final String code;
  final String libelle;

  const MotifSignalement({required this.code, required this.libelle});

  /// « Autre » exige une description (règle revérifiée par le backend).
  bool get exigeDescription => code == 'AUTRE';

  factory MotifSignalement.fromJson(Map<String, dynamic> json) =>
      MotifSignalement(
        code: json['code'] as String? ?? '',
        libelle: json['libelle'] as String? ?? '',
      );
}

/// Signalement d'un professionnel par le client connecté.
///   GET  /signalements/motifs
///   POST /signalements
class SignalementRepository {
  final ApiClient _client;

  SignalementRepository(this._client);

  Future<List<MotifSignalement>> getMotifs() async {
    final response = await _client.get('/signalements/motifs');
    final list = response.data as List<dynamic>? ?? [];
    return list
        .map((e) => MotifSignalement.fromJson(e as Map<String, dynamic>))
        .toList();
  }

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
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
      },
    );
  }
}

final signalementRepositoryProvider = Provider<SignalementRepository>((ref) {
  return SignalementRepository(ref.watch(apiClientProvider));
});

final motifsSignalementProvider =
    FutureProvider.autoDispose<List<MotifSignalement>>((ref) {
      return ref.read(signalementRepositoryProvider).getMotifs();
    });
