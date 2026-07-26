import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../shared/services/api_client.dart';
import '../models/patient_model.dart';

class AuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSource(this._apiClient);

  /// Étape 1 du login : le backend vérifie d'abord l'email + mot de passe,
  /// et n'envoie le code OTP par email que si la paire est correcte.
  Future<void> demanderOtp({
    required String email,
    required String motDePasse,
  }) async {
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
    try {
      final response = await _apiClient.dio.get(ApiConstants.me);
      final data = response.data as Map<String, dynamic>;
      return PatientModel.fromJson(data['utilisateur'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  /// Inscription libre (compte patient/famille venu de la vitrine
  /// publique) — `POST /auth/register`, toujours avec `role: 'patient'`
  /// (jamais exposé à l'utilisateur dans l'UI, cf. README section 5).
  Future<void> inscrire({
    required String nom,
    required String prenom,
    required String email,
    required String telephone,
    required String motDePasse,
  }) async {
    try {
      await _apiClient.dio.post(
        ApiConstants.register,
        data: {
          'nom': nom,
          'prenom': prenom,
          'email': email,
          'telephone': telephone,
          'motDePasse': motDePasse,
          'role': 'patient',
        },
      );
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  /// `POST /auth/verify-otp` — vérifie le code reçu après inscription.
  /// Distincte de `verify-login-otp` utilisée pour la connexion.
  Future<Map<String, dynamic>> verifierInscriptionOtp({
    required String email,
    required String code,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.verifyRegisterOtp,
        data: {'email': email, 'code': code},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  /// `POST /auth/resend-otp` — renvoie un code d'inscription.
  Future<void> renvoyerOtpInscription({required String email}) async {
    try {
      await _apiClient.dio.post(ApiConstants.resendRegisterOtp, data: {'email': email});
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  /// ⚠️ TEMPORAIRE — appelle /auth/test/login (bypass OTP). N'existe que
  /// côté backend démarré avec NODE_ENV !== 'production' (voir
  /// EnvConfig.otpBypassActive / routes/authRoutes.js) : contre la prod
  /// Vercel, cet appel renverra 404 par design.
  Future<Map<String, dynamic>> loginTest({
    required String email,
    required String motDePasse,
  }) async {
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
