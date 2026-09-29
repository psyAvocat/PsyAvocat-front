import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_providers.dart';
import '../models/profil_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Repository Profil — Interface abstraite & Implémentation API
// ─────────────────────────────────────────────────────────────────────────────

abstract class ProfilRepository {
  Future<ProfilModel?> getCurrentProfile();
  Future<ProfilModel> updateProfile({String? nom, String? prenom, String? telephone, String? ville});
  Future<ProfilModel> createPatientProfile({required String nom, required String prenom, String? telephone, String? ville});
  Future<ProfilModel> createJusticiableProfile({required String nom, required String prenom, String? telephone, String? ville});
}

class ApiProfilRepository implements ProfilRepository {
  final ApiClient _client;

  ApiProfilRepository(this._client);

  @override
  Future<ProfilModel?> getCurrentProfile() async {
    try {
      final response = await _client.get('/profil');
      return ProfilModel.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ProfilModel> updateProfile({
    String? nom,
    String? prenom,
    String? telephone,
    String? ville,
  }) async {
    final response = await _client.put('/profil', data: {
      'nom': ?nom,
      'prenom': ?prenom,
      'telephone': ?telephone,
      'ville': ?ville,
    });
    return ProfilModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<ProfilModel> createPatientProfile({
    required String nom,
    required String prenom,
    String? telephone,
    String? ville,
  }) async {
    final response = await _client.post('/profil/patient', data: {
      'nom': nom,
      'prenom': prenom,
      'telephone': ?telephone,
      'ville': ?ville,
    });
    return ProfilModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<ProfilModel> createJusticiableProfile({
    required String nom,
    required String prenom,
    String? telephone,
    String? ville,
  }) async {
    final response = await _client.post('/profil/justiciable', data: {
      'nom': nom,
      'prenom': prenom,
      'telephone': ?telephone,
      'ville': ?ville,
    });
    return ProfilModel.fromJson(response.data as Map<String, dynamic>);
  }
}

final profilRepositoryProvider = Provider<ProfilRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return ApiProfilRepository(client);
});
