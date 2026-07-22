import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/dashboard_remote_datasource.dart';
import '../../domain/entities/dashboard_entities.dart';

final dashboardRemoteDataSourceProvider = Provider<DashboardRemoteDataSource>((ref) {
  return DashboardRemoteDataSource(ref.watch(apiClientProvider));
});

/// Tableau de bord santé (UC2) : un [FutureProvider] unique, la page consomme
/// un `AsyncValue<TableauDeBord>` et gère elle-même chargement/erreur/retry
/// via `.when(...)` + `RefreshIndicator` (voir `dashboard_page.dart`).
final tableauDeBordProvider = FutureProvider.autoDispose<TableauDeBord>((ref) {
  return ref.watch(dashboardRemoteDataSourceProvider).obtenirTableauDeBord();
});
