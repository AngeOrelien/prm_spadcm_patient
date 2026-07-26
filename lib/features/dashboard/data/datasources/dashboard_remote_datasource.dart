import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../shared/services/api_client.dart';
import '../../domain/entities/dashboard_entities.dart';
import '../models/dashboard_models.dart';

/// Toutes les requêtes du feature Dashboard vers `prm-spad-backend`.
/// Réutilise l'[ApiClient] unique (token + refresh automatiques déjà gérés),
/// convertit chaque erreur Dio en [AppException] lisible.
class DashboardRemoteDataSource {
  final ApiClient _apiClient;

  DashboardRemoteDataSource(this._apiClient);

  /// Récupère en un seul appel tout ce qu'affiche l'onglet Accueil : fiche
  /// patient, AVS assigné, dernier rapport validé, traitements en cours,
  /// prochain rendez-vous, alertes ouvertes, documents récents et compteur
  /// de notifications non lues.
  /// Le backend renvoie `{ success, patient, avsAssigne, dernierRapport,
  /// traitementsActifs, prochainRendezVous, alertesOuvertes,
  /// documentsRecents, notificationsNonLues }` — `TableauDeBordModel.fromJson`
  /// lit directement ces clés au premier niveau.
  Future<TableauDeBord> obtenirTableauDeBord() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.monTableauDeBord);
      return TableauDeBordModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }
}
