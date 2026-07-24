import 'dart:async';

import '../../../../core/config/app_config.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../shared/services/secure_storage_service.dart';
import '../../domain/entities/patient.dart';
import '../../domain/repositories/auth_repository.dart';

/// Implémentation **mock** de [AuthRepository] : accepte n'importe quel
/// couple email/mot de passe non vide (le vrai backend n'étant pas encore
/// branché — voir README section 6/13), simule l'envoi d'un code OTP et
/// n'accepte que le code `123456` pour la vérification.
///
/// Une fois `prm-spad-backend` prêt côté V2, il suffira de repasser
/// [AppConfig.useMockData] à `false` : `AuthRepositoryImpl` (déjà écrit et
/// inchangé) reprendra la main sans aucune autre modification côté UI.
class AuthMockRepository implements AuthRepository {
  final SecureStorageService _storage;

  AuthMockRepository(this._storage);

  static const codeOtpValide = '123456';

  static const _patientMock = Patient(
    id: 'user-famille-1',
    nom: 'Mballa',
    prenom: 'Paul',
    email: 'paul.mballa@example.com',
    role: RoleCompteMenager.famille,
  );

  Future<void> _latence() => Future.delayed(AppConfig.mockLatency);

  @override
  Future<void> demanderCodeConnexion({
    required String email,
    required String motDePasse,
  }) async {
    await _latence();
    if (email.trim().isEmpty || motDePasse.trim().isEmpty) {
      throw const AppException('Email et mot de passe requis.');
    }
    // En mock, le "code" à saisir est toujours 123456 (voir écran OTP).
  }

  @override
  Future<Patient> verifierCodeConnexion({
    required String email,
    required String code,
  }) async {
    await _latence();
    if (code.trim() != codeOtpValide) {
      throw AppException('Code invalide. (Astuce : utilisez $codeOtpValide en mode démo)');
    }
    await _storage.saveTokens(accessToken: 'mock-access-token', refreshToken: 'mock-refresh-token');
    return _patientMock;
  }

  @override
  Future<Patient?> restaurerSession() async {
    final token = await _storage.getAccessToken();
    if (token == null) return null;
    return _patientMock;
  }

  @override
  Future<void> deconnecter() => _storage.clear();

  @override
  Future<Patient> connexionTest({
    required String email,
    required String motDePasse,
  }) async {
    await _latence();
    await _storage.saveTokens(accessToken: 'mock-access-token', refreshToken: 'mock-refresh-token');
    return _patientMock;
  }
}
