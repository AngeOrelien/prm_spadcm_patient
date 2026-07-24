import 'package:dio/dio.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../shared/mock/mock_api.dart';
import '../../../../shared/services/api_client.dart';
import '../models/patient_model.dart';

/// Tant que `AppConfig.useMockBackend` est `true`, chaque méthode répond
/// depuis [MockApi] (aucun compte/mot de passe requis, code OTP toujours
/// accepté). Pour reconnecter au vrai backend : passer le flag à `false`
/// dans `core/config/app_config.dart`, le code Dio ci-dessous est déjà prêt.
class AuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSource(this._apiClient);

  /// Étape 1 du login : le backend vérifie d'abord l'email + mot de passe,
  /// et n'envoie le code OTP par email que si la paire est correcte.
  Future<void> demanderOtp({
    required String email,
    required String motDePasse,
  }) async {
    if (AppConfig.useMockBackend) {
      await MockApi.login(email: email, motDePasse: motDePasse);
      return;
    }
    try {
      await _apiClient.dio.post(
        ApiConstants.requestOtp,
        data: {'email': email, 'motDePasse': motDePasse},
      );
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  Future<Map<String, dynamic>> verifierOtp({
    required String email,
    required String code,
  }) async {
    if (AppConfig.useMockBackend) {
      return MockApi.login(email: email, motDePasse: '');
    }
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.verifyLoginOtp,
        data: {'email': email, 'code': code},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  Future<PatientModel> obtenirProfil() async {
    if (AppConfig.useMockBackend) {
      final data = await MockApi.profil();
      return PatientModel.fromJson(data['utilisateur'] as Map<String, dynamic>);
    }
    try {
      final response = await _apiClient.dio.get(ApiConstants.me);
      final data = response.data as Map<String, dynamic>;
      return PatientModel.fromJson(data['utilisateur'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  /// ⚠️ TEST — appelle /auth/test/login (bypass OTP), route uniquement
  /// montée côté backend si NODE_ENV !== 'production'.
  Future<Map<String, dynamic>> loginTest({
    required String email,
    required String motDePasse,
  }) async {
    if (AppConfig.useMockBackend) {
      return MockApi.login(email: email, motDePasse: motDePasse);
    }
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.testLogin,
        data: {'email': email, 'motDePasse': motDePasse},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }
}
