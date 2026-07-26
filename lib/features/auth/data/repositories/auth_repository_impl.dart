import '../../../../shared/services/secure_storage_service.dart';
import '../../domain/entities/patient.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/patient_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final SecureStorageService _storage;

  AuthRepositoryImpl(this._remoteDataSource, this._storage);

  @override
  Future<void> demanderCodeConnexion({
    required String email,
    required String motDePasse,
  }) {
    return _remoteDataSource.demanderOtp(
      email: email.trim().toLowerCase(),
      motDePasse: motDePasse,
    );
  }

  @override
  Future<Patient> verifierCodeConnexion({
    required String email,
    required String code,
  }) async {
    final data = await _remoteDataSource.verifierOtp(
      email: email.trim().toLowerCase(),
      code: code.trim(),
    );

    await _storage.saveTokens(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
    );

    return PatientModel.fromJson(data['utilisateur'] as Map<String, dynamic>);
  }

  @override
  Future<Patient?> restaurerSession() async {
    final accessToken = await _storage.getAccessToken();
    if (accessToken == null) return null;

    try {
      return await _remoteDataSource.obtenirProfil();
    } catch (_) {
      // token invalide/expiré et non rafraîchissable -> pas de session
      await _storage.clear();
      return null;
    }
  }

  @override
  Future<void> deconnecter() => _storage.clear();

  @override
  Future<void> inscrire({
    required String nom,
    required String prenom,
    required String email,
    required String telephone,
    required String motDePasse,
  }) {
    return _remoteDataSource.inscrire(
      nom: nom.trim(),
      prenom: prenom.trim(),
      email: email.trim().toLowerCase(),
      telephone: telephone.trim(),
      motDePasse: motDePasse,
    );
  }

  @override
  Future<Patient> verifierInscription({
    required String email,
    required String code,
  }) async {
    final data = await _remoteDataSource.verifierInscriptionOtp(
      email: email.trim().toLowerCase(),
      code: code.trim(),
    );

    await _storage.saveTokens(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
    );

    return PatientModel.fromJson(data['utilisateur'] as Map<String, dynamic>);
  }

  @override
  Future<void> renvoyerOtpInscription({required String email}) {
    return _remoteDataSource.renvoyerOtpInscription(email: email.trim().toLowerCase());
  }

  @override
  Future<Patient> connexionTest({
    required String email,
    required String motDePasse,
  }) async {
    final data = await _remoteDataSource.loginTest(
      email: email.trim().toLowerCase(),
      motDePasse: motDePasse,
    );

    await _storage.saveTokens(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
    );

    return PatientModel.fromJson(data['utilisateur'] as Map<String, dynamic>);
  }
}
