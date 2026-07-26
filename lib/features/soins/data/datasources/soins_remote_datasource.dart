import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../shared/services/api_client.dart';
import '../../domain/entities/soins_entities.dart';
import '../models/soins_models.dart';

class SoinsRemoteDataSource {
  final ApiClient _apiClient;

  SoinsRemoteDataSource(this._apiClient);

  /// `GET /soins` — public, ne nécessite aucun token (voir §5 du README
  /// frontend). Fonctionne à l'identique depuis la vitrine non connectée et
  /// depuis l'onglet Soins authentifié.
  Future<List<SoinCatalogue>> obtenirCatalogue() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.catalogueSoins);
      final data = response.data as Map<String, dynamic>;
      return (data['soins'] as List)
          .map((e) => SoinCatalogueModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  /// `GET /soins/:id` — public, utile pour un lien direct vers l'écran de
  /// détail (`/soins-public/:id`) sans être passé par la liste au préalable.
  Future<SoinCatalogue> obtenirSoin(String soinId) async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.soin(soinId));
      final data = response.data as Map<String, dynamic>;
      final soinJson = (data['soin'] ?? data) as Map<String, dynamic>;
      return SoinCatalogueModel.fromJson(soinJson);
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  /// `GET /souscriptions/moi` — pas `/souscriptions` tout court, qui est
  /// réservé coordonnateur/administrateur (403 pour un patient).
  Future<List<Souscription>> obtenirSouscriptions() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.mesSouscriptions);
      final data = response.data as Map<String, dynamic>;
      return (data['souscriptions'] as List)
          .map((e) => SouscriptionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  Future<List<Paiement>> obtenirPaiements() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.mesPaiements);
      final data = response.data as Map<String, dynamic>;
      return (data['paiements'] as List)
          .map((e) => PaiementModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  /// Souscrit au soin choisi (`POST /souscriptions`). `patientInfo` (nom,
  /// prénom, allergies, informationsSante, regimeAlimentaire) est transmis
  /// directement ici — le backend crée automatiquement le dossier `Patient`
  /// à la confirmation du paiement, il n'est pas nécessaire de créer un
  /// dossier au préalable via `POST /patients/moi` (voir §0/§7 du README
  /// frontend). Renvoie l'id de la souscription créée
  /// (statut `en_attente_paiement`).
  ///
  /// Si le patient a déjà une souscription active/en attente, le backend
  /// renvoie `409` — laissé tel quel, l'appelant relaie le message renvoyé
  /// (déjà rédigé pour l'utilisateur final) et propose "terminer" (6.1.1).
  Future<String> souscrire({
    required String soinId,
    PatientInfoSouscription? patientInfo,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.souscriptions,
        data: {
          'soinId': soinId,
          if (patientInfo != null && patientInfo.toJson().isNotEmpty)
            'patientInfo': patientInfo.toJson(),
        },
      );
      final data = response.data as Map<String, dynamic>;
      final souscriptionJson = (data['souscription'] ?? data) as Map<String, dynamic>;
      return (souscriptionJson['_id'] ?? souscriptionJson['id']).toString();
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  /// Termine (résilie) une souscription **active** pour libérer le patient
  /// et lui permettre de souscrire à un autre soin (`PATCH
  /// /souscriptions/:id/terminer`). Sur une souscription encore
  /// `en_attente_paiement`, c'est [annulerSouscription] qu'il faut utiliser.
  Future<void> terminerSouscription(String souscriptionId) async {
    try {
      await _apiClient.dio.patch(ApiConstants.souscriptionTerminer(souscriptionId));
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  /// Annule une souscription encore `en_attente_paiement` (avant tout
  /// paiement confirmé) — distincte de `terminerSouscription` qui ne
  /// s'applique qu'à une souscription déjà `active`.
  Future<void> annulerSouscription(String souscriptionId) async {
    try {
      await _apiClient.dio.patch(ApiConstants.souscriptionAnnuler(souscriptionId));
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  /// `POST /paiements` — crée le paiement associé à une souscription en
  /// attente. Renvoie l'id du paiement créé, à utiliser ensuite avec
  /// [simulerPaiement] en environnement local/dev.
  Future<String> creerPaiement({
    required String souscriptionId,
    String moyenPaiement = 'mobile_money',
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.paiements,
        data: {'souscriptionId': souscriptionId, 'moyenPaiement': moyenPaiement},
      );
      final data = response.data as Map<String, dynamic>;
      final paiementJson = (data['paiement'] ?? data) as Map<String, dynamic>;
      return (paiementJson['_id'] ?? paiementJson['id']).toString();
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  /// `POST /paiements/:id/simuler` — **réservé au développement/local**
  /// (répond `403` en production sans `PAIEMENT_SIMULATION_ACTIVE=true`, cf.
  /// §6.3 du TESTING-README backend). Confirme immédiatement le paiement et
  /// active la souscription, exactement comme le ferait le vrai webhook.
  Future<void> simulerPaiement(String paiementId, {bool reussi = true}) async {
    try {
      await _apiClient.dio.post(
        ApiConstants.paiementSimuler(paiementId),
        data: {'statut': reussi ? 'reussi' : 'echoue'},
      );
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }
}
