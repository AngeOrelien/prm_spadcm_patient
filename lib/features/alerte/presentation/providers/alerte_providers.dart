import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../shared/services/api_client.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';

class AlerteRemoteDataSource {
  final ApiClient _apiClient;

  AlerteRemoteDataSource(this._apiClient);

  /// UC4 "Déclencher alerte SOS". Le backend déduit `patientId` de la fiche
  /// liée au compte connecté ; l'app n'a jamais besoin de le transmettre.
  Future<void> declencherAlerte({String? description}) async {
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
