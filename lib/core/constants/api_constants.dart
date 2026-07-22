/// Configuration de l'accès au backend Node/Express (prm-spad-backend).
///
/// C'est le **même backend unique** que celui utilisé par l'app Personnel —
/// pas de gateway ni de service dédié pour l'app Patients/Familles, cf.
/// section 6 du README principal du projet.
///
/// En développement, le backend tourne en local sur le port 4000.
/// - Émulateur Android  -> 10.0.2.2 (alias de "localhost" de la machine hôte)
/// - Simulateur iOS     -> localhost fonctionne directement
/// - Appareil physique  -> remplace par l'IP locale de ta machine (ex: 192.168.1.x)
///
/// Surcharge possible au lancement sans toucher au code :
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.50:4000/api
class ApiConstants {
  ApiConstants._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:4000/api',
  );

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
}
