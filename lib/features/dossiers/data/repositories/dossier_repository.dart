import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_providers.dart';
import '../models/dossier_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Repository Dossier — workflow juridique (API Spring Boot)
//   POST /dossiers                                → création
//   POST /dossiers/{id}/pieces-jointes            → dépôt (bucket privé)
//   POST /dossiers/{id}/soumissions               → soumission à un avocat
//   GET  /dossiers, /dossiers/{id}                → suivi des réponses
// Les erreurs sont propagées : jamais converties en liste vide.
// ─────────────────────────────────────────────────────────────────────────────

abstract class DossierRepository {
  Future<List<DossierModel>> getMyDossiers();
  Future<DossierModel> getDossierById(String id);
  Future<DossierModel> createDossier({
    required String titre,
    required String description,
    String? specialiteId,
  });
  Future<void> ajouterPieceJointe({
    required String dossierId,
    required String nom,
    required Uint8List bytes,
  });
  Future<void> soumettre({required String dossierId, required String avocatId});
}

class ApiDossierRepository implements DossierRepository {
  final ApiClient _client;

  ApiDossierRepository(this._client);

  @override
  Future<List<DossierModel>> getMyDossiers() async {
    final response = await _client.get('/dossiers');
    final list = response.data as List<dynamic>? ?? [];
    return list
        .map((e) => DossierModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<DossierModel> getDossierById(String id) async {
    final response = await _client.get('/dossiers/$id');
    return DossierModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<DossierModel> createDossier({
    required String titre,
    required String description,
    String? specialiteId,
  }) async {
    final response = await _client.post(
      '/dossiers',
      data: {
        'titre': titre,
        'description': description,
        'specialiteId': ?specialiteId,
      },
    );
    return DossierModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> ajouterPieceJointe({
    required String dossierId,
    required String nom,
    required Uint8List bytes,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: nom,
        contentType: DioMediaType.parse(typeMimeDe(nom)),
      ),
    });
    await _client.post(
      '/dossiers/$dossierId/pieces-jointes',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
  }

  @override
  Future<void> soumettre({
    required String dossierId,
    required String avocatId,
  }) async {
    await _client.post(
      '/dossiers/$dossierId/soumissions',
      data: {'avocatId': avocatId},
    );
  }
}

/// Type MIME déclaré au backend (qui le revérifie) d'après l'extension.
String typeMimeDe(String nom) {
  final ext = nom.contains('.') ? nom.split('.').last.toLowerCase() : '';
  switch (ext) {
    case 'pdf':
      return 'application/pdf';
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'png':
      return 'image/png';
    case 'doc':
      return 'application/msword';
    case 'docx':
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    default:
      return 'application/octet-stream';
  }
}

final dossierRepositoryProvider = Provider<DossierRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return ApiDossierRepository(client);
});
