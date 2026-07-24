import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/dossier_remote_datasource.dart';
import '../../domain/entities/dossier_entities.dart';

final dossierRemoteDataSourceProvider = Provider<DossierRemoteDataSource>((ref) {
  return DossierRemoteDataSource(ref.watch(apiClientProvider));
});

final resumePatientProvider = FutureProvider.autoDispose<ResumePatient>((ref) {
  return ref.watch(dossierRemoteDataSourceProvider).obtenirResumePatient();
});

final traitementsProvider = FutureProvider.autoDispose<List<Traitement>>((ref) {
  return ref.watch(dossierRemoteDataSourceProvider).obtenirTraitements();
});

final rapportsJournaliersProvider = FutureProvider.autoDispose<List<RapportJournalier>>((ref) {
  return ref.watch(dossierRemoteDataSourceProvider).obtenirRapports();
});

final appreciationsProvider = FutureProvider.autoDispose<List<Appreciation>>((ref) {
  return ref.watch(dossierRemoteDataSourceProvider).obtenirAppreciations();
});

final documentsMedicauxProvider = FutureProvider.autoDispose<List<DocumentMedicalDossier>>((ref) {
  return ref.watch(dossierRemoteDataSourceProvider).obtenirDocuments();
});

final rendezVousProvider = FutureProvider.autoDispose<List<RendezVousDossier>>((ref) {
  return ref.watch(dossierRemoteDataSourceProvider).obtenirRendezVous();
});

/// Contrôleur de l'action "Noter l'AVS" (UC7).
class NotationAvsController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> noter({required String rapportId, required int note, required String commentaire}) async {
    state = const AsyncLoading();
    try {
      await ref.read(dossierRemoteDataSourceProvider).noterAvs(
            rapportId: rapportId,
            note: note,
            commentaire: commentaire,
          );
      ref.invalidate(appreciationsProvider);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final notationAvsControllerProvider = AsyncNotifierProvider<NotationAvsController, void>(
  NotationAvsController.new,
);
