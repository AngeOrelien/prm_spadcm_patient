import 'package:dio/dio.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../shared/mock/mock_api.dart';
import '../../../../shared/services/api_client.dart';
import '../../domain/entities/soins_entities.dart';
import '../models/soins_models.dart';

class SoinsRemoteDataSource {
  final ApiClient _apiClient;

  SoinsRemoteDataSource(this._apiClient);

  Future<List<SoinCatalogue>> obtenirCatalogue() async {
    if (AppConfig.useMockBackend) {
      final data = await MockApi.catalogueSoins();
      return data.map(SoinCatalogueModel.fromJson).toList();
    }
    try {
      final response = await _apiClient.dio.get(ApiConstants.catalogueSoins);
      return (response.data as List).map((e) => SoinCatalogueModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  Future<List<Souscription>> obtenirSouscriptions() async {
    if (AppConfig.useMockBackend) {
      final data = await MockApi.souscriptions();
      return data.map(SouscriptionModel.fromJson).toList();
    }
    try {
      final response = await _apiClient.dio.get(ApiConstants.souscriptions);
      return (response.data as List).map((e) => SouscriptionModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  Future<List<Paiement>> obtenirPaiements() async {
    if (AppConfig.useMockBackend) {
      final data = await MockApi.paiements();
      return data.map(PaiementModel.fromJson).toList();
    }
    try {
      final response = await _apiClient.dio.get(ApiConstants.mesPaiements);
      return (response.data as List).map((e) => PaiementModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  /// Souscrit au soin choisi + déclenche le paiement (webhook de
  /// confirmation simulé côté mock — voir `MockApi.souscrire`).
  Future<void> souscrire(String soinId) async {
    if (AppConfig.useMockBackend) {
      await MockApi.souscrire(soinId: soinId);
      return;
    }
    try {
      await _apiClient.dio.post(ApiConstants.souscriptions, data: {'soinId': soinId});
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }
}
