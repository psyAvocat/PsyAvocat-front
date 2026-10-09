import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_providers.dart';
import '../models/profil_model.dart';

/// Profil de l'utilisateur connecté (Spring Boot `/api/profil`).
/// Les erreurs remontent (AppException) : l'écran affiche un état d'erreur réel.
abstract class ProfilRepository {
  Future<ProfilModel> getCurrentProfile();

  /// Profil client unique, valable dans les univers Avocat et Psychologue.
  Future<ProfilModel> createClientProfile({
    required String nom,
    required String prenom,
    required String telephone,
  });

  /// Champs modifiables par un client : nom, prénom, téléphone.
  /// L'email (identifiant Firebase) n'est pas modifiable ici.
  Future<ProfilModel> updateProfile({
    required String nom,
    required String prenom,
    required String telephone,
  });

  /// Photo de profil envoyée au backend (stockage R2 côté serveur).
  Future<ProfilModel> uploadPhoto({
    required Uint8List bytes,
    required String fileName,
  });

  Future<ProfilModel> deletePhoto();
}

class ApiProfilRepository implements ProfilRepository {
  final ApiClient _client;

  ApiProfilRepository(this._client);

  @override
  Future<ProfilModel> getCurrentProfile() async {
    final response = await _client.get('/profil');
    return ProfilModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<ProfilModel> createClientProfile({
    required String nom,
    required String prenom,
    required String telephone,
  }) async {
    final response = await _client.post(
      '/profil/client',
      data: {'nom': nom, 'prenom': prenom, 'telephone': telephone},
    );
    return ProfilModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<ProfilModel> updateProfile({
    required String nom,
    required String prenom,
    required String telephone,
  }) async {
    final response = await _client.put(
      '/profil',
      data: {'nom': nom, 'prenom': prenom, 'telephone': telephone},
    );
    return ProfilModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<ProfilModel> uploadPhoto({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: fileName),
    });
    final response = await _client.post(
      '/profil/photo',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return ProfilModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<ProfilModel> deletePhoto() async {
    final response = await _client.delete('/profil/photo');
    return ProfilModel.fromJson(response.data as Map<String, dynamic>);
  }
}

final profilRepositoryProvider = Provider<ProfilRepository>((ref) {
  return ApiProfilRepository(ref.watch(apiClientProvider));
});
