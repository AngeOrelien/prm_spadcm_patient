import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/config/env_config.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/soins_remote_datasource.dart';
import '../../domain/entities/soins_entities.dart';

final soinsRemoteDataSourceProvider = Provider<SoinsRemoteDataSource>((ref) {
  return SoinsRemoteDataSource(ref.watch(apiClientProvider));
});

/// Mémorise le soin qu'un visiteur non connecté voulait souscrire avant
/// d'être envoyé vers `/inscription` (ou `/login`) — le router (voir
/// `router/app_router.dart`) le consulte une fois la connexion établie pour
/// renvoyer directement vers `/souscrire/:soinId` plutôt que vers
/// `/accueil` (README frontend §5/§7.2).
final pendingSoinIdProvider = StateProvider<String?>((ref) => null);

/// `GET /soins` — public. Utilisé aussi bien par la vitrine non connectée
/// que par l'onglet Soins authentifié (même provider, même appel).
final catalogueSoinsProvider = FutureProvider.autoDispose<List<SoinCatalogue>>((ref) {
  return ref.watch(soinsRemoteDataSourceProvider).obtenirCatalogue();
});

/// `GET /soins/:id` — utile pour un lien direct vers l'écran de détail
/// public sans être passé par le catalogue au préalable.
final soinDetailProvider = FutureProvider.autoDispose.family<SoinCatalogue, String>((ref, soinId) {
  return ref.watch(soinsRemoteDataSourceProvider).obtenirSoin(soinId);
});

final souscriptionsProvider = FutureProvider.autoDispose<List<Souscription>>((ref) {
  return ref.watch(soinsRemoteDataSourceProvider).obtenirSouscriptions();
});

final paiementsProvider = FutureProvider.autoDispose<List<Paiement>>((ref) {
  return ref.watch(soinsRemoteDataSourceProvider).obtenirPaiements();
});

/// Résultat de l'enchaînement souscription -> paiement -> simulation,
/// affiché différemment selon le cas (§7.2 du README frontend).
enum ResultatSouscription {
  /// Paiement simulé et confirmé immédiatement (environnement local/dev).
  confirmee,

  /// Paiement créé mais pas encore confirmé (environnement production,
  /// webhook réel à venir) — souscription en attente.
  enAttenteConfirmation,
}

/// Contrôleur de l'enchaînement complet "souscrire" (formulaire patientInfo
/// -> `POST /souscriptions` -> `POST /paiements` -> simulation en dev) :
/// expose un état de chargement dédié pour ne pas bloquer toute la page
/// pendant l'appel.
class SouscriptionController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Lance l'enchaînement complet. En cas de `409` (souscription déjà en
  /// cours ailleurs), l'erreur remonte telle quelle dans `state.error` — son
  /// message (déjà rédigé pour l'utilisateur final par le backend) est à
  /// afficher directement, avec une proposition de "terminer" la
  /// souscription actuelle (voir [TerminerSouscriptionController]).
  Future<ResultatSouscription?> souscrireEtPayer({
    required String soinId,
    PatientInfoSouscription? patientInfo,
    String moyenPaiement = 'mobile_money',
  }) async {
    state = const AsyncLoading();
    try {
      final dataSource = ref.read(soinsRemoteDataSourceProvider);

      final souscriptionId = await dataSource.souscrire(soinId: soinId, patientInfo: patientInfo);
      final paiementId = await dataSource.creerPaiement(
        souscriptionId: souscriptionId,
        moyenPaiement: moyenPaiement,
      );

      ResultatSouscription resultat;
      if (!EnvConfig.isVercel) {
        // Local/dev : confirmation immédiate, pas d'attente d'un vrai
        // webhook (voir `PAIEMENT_SIMULATION_ACTIVE` côté backend).
        await dataSource.simulerPaiement(paiementId, reussi: true);
        resultat = ResultatSouscription.confirmee;
      } else {
        // Production : la route de simulation répond 403 par design, on
        // laisse le vrai webhook confirmer plus tard.
        resultat = ResultatSouscription.enAttenteConfirmation;
      }

      ref.invalidate(souscriptionsProvider);
      ref.invalidate(paiementsProvider);
      state = const AsyncData(null);
      return resultat;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }
}

final souscriptionControllerProvider = AsyncNotifierProvider<SouscriptionController, void>(
  SouscriptionController.new,
);

/// Contrôleur dédié à "Mettre fin à ma souscription actuelle" (§7.3 du
/// README frontend) — état de chargement séparé du reste de la page.
class TerminerSouscriptionController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> terminer(String souscriptionId) async {
    state = const AsyncLoading();
    try {
      await ref.read(soinsRemoteDataSourceProvider).terminerSouscription(souscriptionId);
      ref.invalidate(souscriptionsProvider);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final terminerSouscriptionControllerProvider =
    AsyncNotifierProvider<TerminerSouscriptionController, void>(
  TerminerSouscriptionController.new,
);
