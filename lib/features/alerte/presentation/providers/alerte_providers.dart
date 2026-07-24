import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../shared/mock/mock_api.dart';
import '../../../../shared/services/api_client.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';

class AlerteRemoteDataSource {
  final ApiClient _apiClient;

  AlerteRemoteDataSource(this._apiClient);

  /// UC4 "Déclencher alerte SOS" : crée l'alerte et notifie (en Phase 3
  /// réelle) l'AVS de garde + le coordonnateur via FCM.
  Future<void> declencherAlerte({String? description}) async {
    if (AppConfig.useMockBackend) {
      await MockApi.declencherAlerte(description: description);
      return;
    }
    try {
      await _apiClient.dio.post(ApiConstants.alertes, data: {'type': 'sos', 'description': description});
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }
}

final alerteRemoteDataSourceProvider = Provider<AlerteRemoteDataSource>((ref) {
  return AlerteRemoteDataSource(ref.watch(apiClientProvider));
});

class DeclenchementAlerteController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> declencher({String? description}) async {
    state = const AsyncLoading();
    try {
      await ref.read(alerteRemoteDataSourceProvider).declencherAlerte(description: description);
      // Le tableau de bord (badge alertes ouvertes) doit refléter la
      // nouvelle alerte immédiatement.
      ref.invalidate(tableauDeBordProvider);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final declenchementAlerteControllerProvider = AsyncNotifierProvider<DeclenchementAlerteController, void>(
  DeclenchementAlerteController.new,
);
