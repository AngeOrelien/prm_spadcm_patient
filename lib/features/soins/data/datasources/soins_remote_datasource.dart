import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../shared/services/api_client.dart';
import '../../domain/entities/soins_entities.dart';
import '../models/soins_models.dart';

class SoinsRemoteDataSource {
  final ApiClient _apiClient;

  SoinsRemoteDataSource(this._apiClient);

  /// `GET /soins`, déjà public côté backend (aucun token nécessaire) : utilisé
  /// aussi bien par l'onglet Soins authentifié que par la vitrine publique.
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

  /// `GET /soins/:id` — utile pour qu'un lien direct vers
  /// `/soins-public/:id` fonctionne sans être passé par le catalogue
  /// d'abord (deep link).
  Future<SoinCatalogue> obtenirSoin(String id) async {
    try {
      final response = await _apiClient.dio.get('${ApiConstants.catalogueSoins}/$id');
      final data = response.data as Map<String, dynamic>;
      final soinJson = data['soin'] as Map<String, dynamic>? ?? data;
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

  /// `POST /souscriptions` — crée la souscription en `en_attente_paiement`
  /// et renvoie son id. `patientInfo` (allergies/informationsSante/
  /// regimeAlimentaire, éventuellement nom/prénom) est transmis dans le
  /// même appel : le dossier `Patient` sera auto-créé côté backend à la
  /// confirmation du paiement, pas ici (README section 0).
  ///
  /// Peut renvoyer un 409 (`AppException.statusCode == 409`) si une
  /// souscription est déjà active — le message backend est déjà rédigé
  /// pour l'utilisateur final, à afficher tel quel.
  Future<String> souscrire({
    required String soinId,
    PatientInfoSouscription? patientInfo,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.souscriptions,
        data: {
          'soinId': soinId,
          if (patientInfo != null) 'patientInfo': patientInfo.toJson(),
        },
      );
      final data = response.data as Map<String, dynamic>;
      final souscriptionJson = data['souscription'] as Map<String, dynamic>? ?? data;
      return (souscriptionJson['_id'] ?? souscriptionJson['id']).toString();
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  /// `POST /paiements` — crée le paiement associé à la souscription tout
  /// juste créée, renvoie l'id du paiement.
  Future<String> creerPaiement({
    required String souscriptionId,
    String moyenPaiement = 'mobile_money',
    String? numeroTelephone,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.paiements,
        data: {
          'souscriptionId': souscriptionId,
          'moyenPaiement': moyenPaiement,
          if (numeroTelephone != null && numeroTelephone.trim().isNotEmpty)
            'numeroTelephone': numeroTelephone.trim(),
        },
      );
      final data = response.data as Map<String, dynamic>;
      final paiementJson = data['paiement'] as Map<String, dynamic>? ?? data;
      return (paiementJson['_id'] ?? paiementJson['id']).toString();
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  /// `POST /paiements/:id/simuler` — confirmation immédiate en local/dev
  /// uniquement. Renvoie 403 en production (`EnvConfig.isVercel == true`),
  /// où l'app ne doit pas appeler cette méthode (voir `souscrire` du
  /// contrôleur, section 7.2 du README).
  Future<void> simulerPaiement(String paiementId) async {
    try {
      await _apiClient.dio.post(ApiConstants.paiementSimuler(paiementId));
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  /// `PATCH /souscriptions/:id/terminer` — met fin à une souscription
  /// `active`. Sur une souscription encore `en_attente_paiement`, le
  /// backend renvoie une erreur explicite invitant à utiliser `annuler` à
  /// la place (relayée telle quelle, pas de duplication de cette logique
  /// côté app).
  Future<void> terminerSouscription(String souscriptionId) async {
    try {
      await _apiClient.dio.patch(ApiConstants.souscriptionTerminer(souscriptionId));
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  /// `PATCH /souscriptions/:id/annuler` — annule une souscription encore
  /// `en_attente_paiement` (paiement pas encore confirmé).
  Future<void> annulerSouscription(String souscriptionId) async {
    try {
      await _apiClient.dio.patch(ApiConstants.souscriptionAnnuler(souscriptionId));
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }
}
