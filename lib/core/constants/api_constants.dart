import '../config/env_config.dart';

/// Configuration de l'accès au backend Node/Express (prm-spad-backend).
///
/// C'est le **même backend unique** que celui utilisé par l'app Personnel —
/// pas de gateway ni de service dédié pour l'app Patients/Familles, cf.
/// section 6 du README principal du projet.
///
/// L'URL de base est pilotée par `EnvConfig` (voir
/// `core/config/env_config.dart`), lui-même lu depuis le fichier `.env` à la
/// racine du projet — même mécanisme que côté app Personnel. Pour basculer
/// entre le backend local et celui déployé sur Vercel, modifie la ligne
/// `APP_ENV` dans `.env` — rien à changer ici. En local :
/// - Appareil physique Android -> `adb reverse tcp:4000 tcp:4000`, puis
///   `http://localhost:4000` fonctionne directement depuis l'appareil.
/// - Émulateur Android  -> 10.0.2.2 (alias de "localhost" de la machine hôte)
///   si tu n'utilises pas adb reverse.
/// - Simulateur iOS     -> localhost fonctionne directement.
class ApiConstants {
  ApiConstants._();

  static String get baseUrl => EnvConfig.apiBaseUrl;

  // --- Auth : compte patient/famille, connexion 100% OTP email ---
  static const String requestOtp = '/auth/request-otp';
  static const String verifyLoginOtp = '/auth/verify-login-otp';
  static const String refreshToken = '/auth/refresh-token';
  static const String me = '/auth/me';

  // --- Tableau de bord santé (UC2) : agrégat servi en un seul appel par
  // GET /api/patients/moi/dashboard, voir `DashboardRemoteDataSource`. ---
  static const String monDossier = '/patients/moi';
  static const String monTableauDeBord = '/patients/moi/dashboard';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  // test login route
  static const String testLogin = '/auth/test/login';

  // --- Soins : catalogue, souscription, paiements (README section 3.1 /
  // routes/soinRoutes.js + souscriptionRoutes.js). ---
  static const String catalogueSoins = '/soins';
  static const String souscriptions = '/souscriptions';
  static const String mesSouscriptions = '/souscriptions/moi';
  static const String mesPaiements = '/paiements/moi';

  // --- Dossier médical : traitements, rapports, documents, rendez-vous ---
  static const String mesTraitements = '/traitements';
  static const String mesRapports = '/rapports';
  static const String mesAppreciations = '/appreciations';
  static const String mesDocuments = '/documents';
  static const String mesRendezVous = '/rendezvous';

  // --- Messagerie & compte famille & alertes ---
  static const String conversations = '/conversations';
  static const String membresFamille = '/patients/moi/membres-famille';
  static const String alertes = '/alertes';
}
