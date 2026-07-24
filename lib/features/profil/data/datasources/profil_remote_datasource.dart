import 'package:dio/dio.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../shared/mock/mock_api.dart';
import '../../../../shared/services/api_client.dart';
import '../../domain/entities/profil_entities.dart';

class ProfilRemoteDataSource {
  final ApiClient _apiClient;

  ProfilRemoteDataSource(this._apiClient);

  Future<List<MembreFamille>> obtenirMembresFamille() async {
    if (AppConfig.useMockBackend) {
      final data = await MockApi.membresFamille();
      return data
          .map((json) => MembreFamille(
                id: (json['id'] ?? json['_id']).toString(),
                nom: json['nom'] as String? ?? '',
                prenom: json['prenom'] as String? ?? '',
                lien: json['lien'] as String? ?? '',
                email: json['email'] as String? ?? '',
                telephone: json['telephone'] as String?,
                estCompteConnecte: json['estCompteConnecte'] as bool? ?? false,
              ))
          .toList();
    }
    try {
      final response = await _apiClient.dio.get(ApiConstants.membresFamille);
      return (response.data as List)
          .map((e) => MembreFamille(
                id: (e['id'] ?? e['_id']).toString(),
                nom: e['nom'] as String? ?? '',
                prenom: e['prenom'] as String? ?? '',
                lien: e['lien'] as String? ?? '',
                email: e['email'] as String? ?? '',
                telephone: e['telephone'] as String?,
                estCompteConnecte: e['estCompteConnecte'] as bool? ?? false,
              ))
          .toList();
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  Future<void> inviterMembreFamille({
    required String nom,
    required String prenom,
    required String lien,
    required String email,
  }) async {
    if (AppConfig.useMockBackend) {
      await MockApi.inviterMembreFamille(nom: nom, prenom: prenom, lien: lien, email: email);
      return;
    }
    try {
      await _apiClient.dio.post(
        ApiConstants.membresFamille,
        data: {'nom': nom, 'prenom': prenom, 'lien': lien, 'email': email},
      );
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  Future<void> definirBiometrie(bool active) async {
    if (AppConfig.useMockBackend) {
      await MockApi.definirBiometrie(active);
      return;
    }
    try {
      await _apiClient.dio.patch('/auth/me', data: {'biometrieActive': active});
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }
}
