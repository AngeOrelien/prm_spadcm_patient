import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../shared/services/api_client.dart';

/// `POST /contact` — formulaire de la vitrine ("poser une question à propos
/// de SPAD"), volontairement public : aucun token n'est attaché (aucun
/// compte requis), distinct de la messagerie interne patient/AVS.
class ContactRemoteDataSource {
  final ApiClient _apiClient;

  ContactRemoteDataSource(this._apiClient);

  /// Un `email` OU un `telephone` est obligatoire (validation backend) — un
  /// `429` est renvoyé au-delà de 10 messages / 15 min par IP (anti-spam).
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
