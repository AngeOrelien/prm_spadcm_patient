import '../../../../core/mock/mock_backend.dart';
import '../../domain/entities/dashboard_entities.dart';

/// Même contrat que [DashboardRemoteDataSource] (voir
/// `dashboard_remote_datasource.dart`), mais servi par le [MockBackend] en
/// mémoire tant que le vrai backend n'est pas branché (`AppConfig.useMockData`).
class DashboardMockDataSource {
  Future<TableauDeBord> obtenirTableauDeBord() {
    return MockBackend.instance.obtenirTableauDeBord();
  }
}
