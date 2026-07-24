import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/soins_remote_datasource.dart';
import '../../domain/entities/soins_entities.dart';

final soinsRemoteDataSourceProvider = Provider<SoinsRemoteDataSource>((ref) {
  return SoinsRemoteDataSource(ref.watch(apiClientProvider));
});

final catalogueSoinsProvider = FutureProvider.autoDispose<List<SoinCatalogue>>((ref) {
  return ref.watch(soinsRemoteDataSourceProvider).obtenirCatalogue();
});

final souscriptionsProvider = FutureProvider.autoDispose<List<Souscription>>((ref) {
  return ref.watch(soinsRemoteDataSourceProvider).obtenirSouscriptions();
});

final paiementsProvider = FutureProvider.autoDispose<List<Paiement>>((ref) {
  return ref.watch(soinsRemoteDataSourceProvider).obtenirPaiements();
});

/// Contrôleur de l'action "souscrire" (bouton sur une carte du catalogue) :
/// expose un état de chargement dédié pour ne pas bloquer toute la page
/// pendant l'appel de paiement.
class SouscriptionController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> souscrire(String soinId) async {
    state = const AsyncLoading();
    try {
      await ref.read(soinsRemoteDataSourceProvider).souscrire(soinId);
      ref.invalidate(souscriptionsProvider);
      ref.invalidate(paiementsProvider);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final souscriptionControllerProvider = AsyncNotifierProvider<SouscriptionController, void>(
  SouscriptionController.new,
);
