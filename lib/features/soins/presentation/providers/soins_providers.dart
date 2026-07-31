import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env_config.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/soins_remote_datasource.dart';
import '../../domain/entities/soins_entities.dart';

final soinsRemoteDataSourceProvider = Provider<SoinsRemoteDataSource>((ref) {
  return SoinsRemoteDataSource(ref.watch(apiClientProvider));
});

final catalogueSoinsProvider = FutureProvider.autoDispose<List<SoinCatalogue>>((ref) {
  return ref.watch(soinsRemoteDataSourceProvider).obtenirCatalogue();
});

/// Détail d'un soin par id, utilisé par `/soins-public/:id` et
/// `soin_detail_page.dart` — d'abord cherché dans le catalogue déjà chargé
/// (évite un appel réseau superflu), sinon `GET /soins/:id` (deep link).
final soinProvider = FutureProvider.autoDispose.family<SoinCatalogue, String>((ref, soinId) async {
  final catalogue = await ref.watch(catalogueSoinsProvider.future);
  for (final soin in catalogue) {
    if (soin.id == soinId) return soin;
  }
  return ref.watch(soinsRemoteDataSourceProvider).obtenirSoin(soinId);
});

final souscriptionsProvider = FutureProvider.autoDispose<List<Souscription>>((ref) {
  return ref.watch(soinsRemoteDataSourceProvider).obtenirSouscriptions();
});

final paiementsProvider = FutureProvider.autoDispose<List<Paiement>>((ref) {
  return ref.watch(soinsRemoteDataSourceProvider).obtenirPaiements();
});

/// Contrôleur de l'action "souscrire" : enchaîne
/// `POST /souscriptions` -> `POST /paiements` -> (local/dev seulement)
/// `POST /paiements/:id/simuler`, README section 7.2.
///
/// En production (Vercel), la simulation n'est pas appelée : la
/// souscription reste `en_attente_paiement` jusqu'à ce que le webhook réel
/// la confirme, et [souscrire] renvoie quand même `true` (l'appel a
/// réussi), à charge de l'écran appelant d'afficher un message adapté via
/// [derniereConfirmationImmediate].
class SouscriptionController extends AsyncNotifier<void> {
  bool _derniereConfirmationImmediate = false;

  bool get derniereConfirmationImmediate => _derniereConfirmationImmediate;

  @override
  Future<void> build() async {}

  /// Étape 1 : crée la souscription (`en_attente_paiement`) sans encore
  /// payer — c'est ce que la nouvelle `PaiementPage` appelle avant de
  /// proposer "Payer maintenant" / "Payer plus tard".
  Future<String?> creerSouscription({
    required String soinId,
    PatientInfoSouscription? patientInfo,
  }) async {
    state = const AsyncLoading();
    try {
      final souscriptionId = await ref.read(soinsRemoteDataSourceProvider).souscrire(
            soinId: soinId,
            patientInfo: patientInfo,
          );
      ref.invalidate(souscriptionsProvider);
      state = const AsyncData(null);
      return souscriptionId;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  /// Étape 2 (immédiate) : paiement mobile money simulé via un numéro de
  /// téléphone. En production (Vercel), la simulation n'est pas appelée :
  /// la souscription reste `en_attente_paiement` jusqu'au webhook réel.
  Future<bool> payer({
    required String souscriptionId,
    required String numeroTelephone,
    String moyenPaiement = 'mobile_money',
  }) async {
    state = const AsyncLoading();
    try {
      final dataSource = ref.read(soinsRemoteDataSourceProvider);
      final paiementId = await dataSource.creerPaiement(
        souscriptionId: souscriptionId,
        moyenPaiement: moyenPaiement,
        numeroTelephone: numeroTelephone,
      );

      _derniereConfirmationImmediate = !EnvConfig.isVercel;
      if (!EnvConfig.isVercel) {
        // Local/dev : confirmation immédiate, pas d'attente de webhook réel.
        await dataSource.simulerPaiement(paiementId);
      }

      ref.invalidate(souscriptionsProvider);
      ref.invalidate(paiementsProvider);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  /// Conservé pour compatibilité (ancien flux "payer directement") :
  /// enchaîne les deux étapes ci-dessus en un seul appel.
  Future<bool> souscrire({
    required String soinId,
    PatientInfoSouscription? patientInfo,
    required String numeroTelephone,
    String moyenPaiement = 'mobile_money',
  }) async {
    final souscriptionId = await creerSouscription(soinId: soinId, patientInfo: patientInfo);
    if (souscriptionId == null) return false;
    return payer(souscriptionId: souscriptionId, numeroTelephone: numeroTelephone, moyenPaiement: moyenPaiement);
  }
}

final souscriptionControllerProvider = AsyncNotifierProvider<SouscriptionController, void>(
  SouscriptionController.new,
);

/// Contrôleur de l'action "mettre fin à ma souscription" (README section
/// 7.3), séparé de [SouscriptionController] pour ne pas mélanger les deux
/// états de chargement dans l'UI.
class TerminerSouscriptionController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> terminer(String souscriptionId) async {
    state = const AsyncLoading();
    try {
      await ref.read(soinsRemoteDataSourceProvider).terminerSouscription(souscriptionId);
      ref.invalidate(souscriptionsProvider);
      ref.invalidate(paiementsProvider);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> annuler(String souscriptionId) async {
    state = const AsyncLoading();
    try {
      await ref.read(soinsRemoteDataSourceProvider).annulerSouscription(souscriptionId);
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

final terminerSouscriptionControllerProvider =
    AsyncNotifierProvider<TerminerSouscriptionController, void>(
  TerminerSouscriptionController.new,
);
