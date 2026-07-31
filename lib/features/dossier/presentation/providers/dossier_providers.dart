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

/// Piloté par le routeur (README onboarding) : tant que ce provider ne
/// renvoie pas `true`, un compte connecté est redirigé vers
/// `/onboarding/dossier` plutôt que vers le shell principal — évite les
/// 404 "compte non relié à une fiche patient" sur le dashboard/dossier/
/// soins/messagerie tant que le patient n'a pas rempli son dossier.
final monDossierExisteProvider = FutureProvider.autoDispose<bool>((ref) {
  final estConnecte = ref.watch(authControllerProvider).value != null;
  if (!estConnecte) return false;
  return ref.watch(dossierRemoteDataSourceProvider).monDossierExiste();
});

/// Contrôleur de l'onboarding "Créer mon dossier" (personnel + médical, en
/// un seul appel `POST /patients/moi` une fois les deux étapes du
/// formulaire remplies).
class CreationDossierController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> creer(Map<String, dynamic> donnees) async {
    state = const AsyncLoading();
    try {
      await ref.read(dossierRemoteDataSourceProvider).creerMonDossier(donnees);
      ref.invalidate(monDossierExisteProvider);
      ref.invalidate(resumePatientProvider);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final creationDossierControllerProvider = AsyncNotifierProvider<CreationDossierController, void>(
  CreationDossierController.new,
);

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