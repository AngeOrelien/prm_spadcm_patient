import 'package:dio/dio.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../shared/mock/mock_api.dart';
import '../../../../shared/services/api_client.dart';
import '../../domain/entities/dashboard_entities.dart';
import '../models/dashboard_models.dart';

/// Toutes les requêtes du feature Dashboard vers `prm-spad-backend`.
/// Même pattern que côté app Personnel (`CoordonnateurRemoteDataSource`) :
/// réutilise l'[ApiClient] unique (token + refresh automatiques déjà gérés),
/// convertit chaque erreur Dio en [AppException] lisible. Tant que
/// `AppConfig.useMockBackend` est `true`, la réponse vient de [MockApi].
class DashboardRemoteDataSource {
  final ApiClient _apiClient;

  DashboardRemoteDataSource(this._apiClient);

  /// Récupère en un seul appel tout ce qu'affiche l'onglet Accueil : fiche
  /// patient, AVS assigné, dernier rapport validé, traitements en cours,
  /// prochain rendez-vous, alertes ouvertes, documents récents et compteur
  /// de notifications non lues.
  Future<TableauDeBord> obtenirTableauDeBord() async {
    if (AppConfig.useMockBackend) {
      final data = await MockApi.tableauDeBord();
      return TableauDeBordModel.fromJson(data);
    }
    try {
      final response = await _apiClient.dio.get(ApiConstants.monTableauDeBord);
      return TableauDeBordModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }
}
