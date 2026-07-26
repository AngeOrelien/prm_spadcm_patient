import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../shared/services/api_client.dart';

/// `POST /contact` — formulaire de contact public de la vitrine
/// (README section 4). Aucun token à attacher : `ApiClient` n'ajoute pas
/// d'`Authorization` en l'absence de session de toute façon.
class ContactRemoteDataSource {
  final ApiClient _apiClient;

  ContactRemoteDataSource(this._apiClient);

  Future<void> envoyerMessage({
    required String nom,
    String? email,
    String? telephone,
    required String sujet,
    required String message,
  }) async {
    try {
      await _apiClient.dio.post(
        ApiConstants.contact,
        data: {
          'nom': nom,
          if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
          if (telephone != null && telephone.trim().isNotEmpty) 'telephone': telephone.trim(),
          'sujet': sujet,
          'message': message,
        },
      );
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }
}
