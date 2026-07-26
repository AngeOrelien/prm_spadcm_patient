import '../entities/patient.dart';

abstract class AuthRepository {
  /// Étape 1 du login : vérifie l'email + mot de passe, puis demande
  /// l'envoi d'un code OTP à l'email donné (le code n'est envoyé que si les
  /// identifiants sont corrects).
  Future<void> demanderCodeConnexion({
    required String email,
    required String motDePasse,
  });

  /// Étape 2 du login : vérifie le code reçu par email, sauvegarde les
  /// tokens en stockage sécurisé et renvoie le profil connecté.
  Future<Patient> verifierCodeConnexion({
    required String email,
    required String code,
  });

  /// Restaure une session existante à partir du token stocké (ex: au
  /// démarrage de l'app), ou renvoie null si aucune session valide.
  Future<Patient?> restaurerSession();

  Future<void> deconnecter();

  /// ⚠️ TEST — connexion en un seul appel, sans étape OTP.
  Future<Patient> connexionTest({
    required String email,
    required String motDePasse,
  });

  /// Étape 1 de l'inscription libre (vitrine) : crée le compte `patient` et
  /// déclenche l'envoi d'un code OTP par email.
  Future<void> inscrire({
    required String nom,
    required String prenom,
    required String email,
    required String telephone,
    required String motDePasse,
  });

  /// Étape 2 : vérifie le code reçu, sauvegarde les tokens et renvoie le
  /// profil du compte tout juste créé.
  Future<Patient> verifierInscriptionOtp({
    required String email,
    required String code,
  });

  Future<void> renvoyerOtpInscription({required String email});
}
