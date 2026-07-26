import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../shared/services/api_client.dart';
import '../../../../shared/services/secure_storage_service.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/patient.dart';
import '../../domain/repositories/auth_repository.dart';

// --- Injection de dépendances (chaque provider ne connaît que la couche du dessous) ---

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.watch(secureStorageServiceProvider));
});

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(ref.watch(apiClientProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.watch(authRemoteDataSourceProvider),
    ref.watch(secureStorageServiceProvider),
  );
});

// --- État de session (qui est connecté ?) ---
//
// AsyncValue<Patient?> :
//  - loading  -> restauration de session en cours (écran splash)
//  - data(null)    -> personne connecté -> écran login
//  - data(Patient) -> connecté -> shell principal (bottom navigation)
//  - error    -> restauration impossible, traité comme non-connecté

class AuthController extends AsyncNotifier<Patient?> {
  @override
  Future<Patient?> build() {
    return ref.read(authRepositoryProvider).restaurerSession();
  }

  void connecte(Patient patient) {
    state = AsyncData(patient);
  }

  Future<void> deconnecter() async {
    await ref.read(authRepositoryProvider).deconnecter();
    state = const AsyncData(null);
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, Patient?>(
  AuthController.new,
);

// --- État du flux de connexion en 2 étapes (email -> code OTP) ---

enum OtpLoginStep { saisieEmail, saisieCode }

class OtpLoginState {
  final OtpLoginStep step;
  final String email;
  final String motDePasse;
  final bool isLoading;
  final String? errorMessage;

  const OtpLoginState({
    this.step = OtpLoginStep.saisieEmail,
    this.email = '',
    this.motDePasse = '',
    this.isLoading = false,
    this.errorMessage,
  });

  OtpLoginState copyWith({
    OtpLoginStep? step,
    String? email,
    String? motDePasse,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return OtpLoginState(
      step: step ?? this.step,
      email: email ?? this.email,
      motDePasse: motDePasse ?? this.motDePasse,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class OtpLoginController extends StateNotifier<OtpLoginState> {
  final AuthRepository _authRepository;
  final AuthController _authController;

  OtpLoginController(this._authRepository, this._authController)
      : super(const OtpLoginState());

  /// Étape 1 : vérifie email + mot de passe côté serveur, puis déclenche
  /// l'envoi du code OTP par email si les identifiants sont valides.
  Future<bool> demanderCode({
    required String email,
    required String motDePasse,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authRepository.demanderCodeConnexion(
        email: email,
        motDePasse: motDePasse,
      );
      state = state.copyWith(
        isLoading: false,
        email: email,
        motDePasse: motDePasse,
        step: OtpLoginStep.saisieCode,
      );
      return true;
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    }
  }

  /// Renvoie un nouveau code OTP en réutilisant l'email + mot de passe déjà
  /// validés à l'étape 1 (évite de redemander le mot de passe uniquement
  /// pour un renvoi de code).
  Future<bool> renvoyerCode() {
    return demanderCode(email: state.email, motDePasse: state.motDePasse);
  }

  Future<bool> verifierCode(String code) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final patient = await _authRepository.verifierCodeConnexion(
        email: state.email,
        code: code,
      );
      _authController.connecte(patient);
      state = state.copyWith(isLoading: false);
      return true;
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    }
  }

  /// Retour à la saisie de l'email (ex: mauvaise adresse tapée).
  void reinitialiser() {
    state = const OtpLoginState();
  }

  /// ⚠️ TEST — connexion directe sans passer par l'écran OTP.
  Future<bool> connexionTest({
    required String email,
    required String motDePasse,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final patient = await _authRepository.connexionTest(
        email: email,
        motDePasse: motDePasse,
      );
      _authController.connecte(patient);
      state = state.copyWith(isLoading: false);
      return true;
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    }
  }
}

final otpLoginControllerProvider =
    StateNotifierProvider.autoDispose<OtpLoginController, OtpLoginState>((ref) {
  return OtpLoginController(
    ref.read(authRepositoryProvider),
    ref.read(authControllerProvider.notifier),
  );
});

// --- État du flux d'inscription en 2 étapes (infos -> code OTP) ---
//
// Calqué sur OtpLoginState/OtpLoginController (README section 5). Garde le
// `soinId` visé (si l'inscription a été déclenchée depuis un tap sur
// "Souscrire" côté vitrine) pour que l'écran appelant sache où rediriger
// une fois l'OTP validé.

enum InscriptionStep { saisieInfos, saisieCode }

class InscriptionState {
  final InscriptionStep step;
  final String email;
  final bool isLoading;
  final String? errorMessage;

  const InscriptionState({
    this.step = InscriptionStep.saisieInfos,
    this.email = '',
    this.isLoading = false,
    this.errorMessage,
  });

  InscriptionState copyWith({
    InscriptionStep? step,
    String? email,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return InscriptionState(
      step: step ?? this.step,
      email: email ?? this.email,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class InscriptionController extends StateNotifier<InscriptionState> {
  final AuthRepository _authRepository;
  final AuthController _authController;

  InscriptionController(this._authRepository, this._authController) : super(const InscriptionState());

  Future<bool> inscrire({
    required String nom,
    required String prenom,
    required String email,
    required String telephone,
    required String motDePasse,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authRepository.inscrire(
        nom: nom,
        prenom: prenom,
        email: email,
        telephone: telephone,
        motDePasse: motDePasse,
      );
      state = state.copyWith(isLoading: false, email: email, step: InscriptionStep.saisieCode);
      return true;
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    }
  }

  Future<bool> verifierCode(String code) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final patient = await _authRepository.verifierInscription(email: state.email, code: code);
      _authController.connecte(patient);
      state = state.copyWith(isLoading: false);
      return true;
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    }
  }

  Future<bool> renvoyerCode() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authRepository.renvoyerOtpInscription(email: state.email);
      state = state.copyWith(isLoading: false);
      return true;
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    }
  }

  void reinitialiser() {
    state = const InscriptionState();
  }
}

final inscriptionControllerProvider =
    StateNotifierProvider.autoDispose<InscriptionController, InscriptionState>((ref) {
  return InscriptionController(
    ref.read(authRepositoryProvider),
    ref.read(authControllerProvider.notifier),
  );
});
