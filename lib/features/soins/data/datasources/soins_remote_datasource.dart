import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../shared/services/api_client.dart';
import '../../domain/entities/soins_entities.dart';
import '../models/soins_models.dart';

class SoinsRemoteDataSource {
  final ApiClient _apiClient;

  SoinsRemoteDataSource(this._apiClient);

  Future<List<SoinCatalogue>> obtenirCatalogue() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.catalogueSoins);
      final data = response.data as Map<String, dynamic>;
      return (data['soins'] as List)
          .map((e) => SoinCatalogueModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  /// `GET /souscriptions/moi` — pas `/souscriptions` tout court, qui est
  /// réservé coordonnateur/administrateur (403 pour un patient).
  Future<List<Souscription>> obtenirSouscriptions() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.mesSouscriptions);
      final data = response.data as Map<String, dynamic>;
      return (data['souscriptions'] as List)
          .map((e) => SouscriptionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  Future<List<Paiement>> obtenirPaiements() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.mesPaiements);
      final data = response.data as Map<String, dynamic>;
      return (data['paiements'] as List)
          .map((e) => PaiementModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  /// Souscrit au soin choisi (`POST /souscriptions`). Le paiement associé
  /// est créé côté backend en attente ; sa confirmation arrive par webhook
  /// (voir `paiementController` / `INTEGRATION.md` du backend) — l'app ne
  /// simule plus de confirmation immédiate côté client.
  Future<void> souscrire(String soinId) async {
    try {
      await _apiClient.dio.post(ApiConstants.souscriptions, data: {'soinId': soinId});
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }
}
