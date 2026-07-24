/// Interrupteur global "mock vs vrai backend".
///
/// Tant que `prm-spad-backend` n'expose pas encore toutes les routes
/// utilisées par cette app (catalogue de soins, souscriptions, dossier
/// complet, messagerie, alertes...), chaque datasource lit ses données
/// depuis `shared/mock/mock_db.dart` au lieu d'appeler [ApiClient].
///
/// Pour reconnecter une feature au vrai backend plus tard :
///   1. Passer [AppConfig.useMockBackend] à `false`.
///   2. Vérifier que les routes utilisées existent bien côté backend
///      (voir `core/constants/api_constants.dart`).
/// Chaque datasource garde son code d'appel Dio existant à côté du mock
/// (branché sur ce flag) pour que la bascule ne demande aucune réécriture.
class AppConfig {
  AppConfig._();

  static const bool useMockBackend = true;

  /// Latence simulée pour que l'UI (loaders, pull-to-refresh...) se
  /// comporte comme avec un vrai réseau.
  static const Duration mockLatency = Duration(milliseconds: 450);
}
