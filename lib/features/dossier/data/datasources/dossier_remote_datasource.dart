import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../shared/services/api_client.dart';
import '../../domain/entities/dossier_entities.dart';
import '../models/dossier_models.dart';

/// Toutes les requêtes du feature Dossier vers `prm-spad-backend`.
///
/// Chaque liste renvoyée par le backend est enveloppée dans un objet
/// `{ success, resultats, <clé> : [...] }` (jamais un tableau JSON brut) —
/// c'est le même format que ce qu'on retrouve côté personnel/coordonnateur.
class DossierRemoteDataSource {
  final ApiClient _apiClient;

  DossierRemoteDataSource(this._apiClient);

  /// `GET /patients/moi` renvoie `{ success, patient, avsAssigne }` : le
  /// contenu utile pour [ResumePatientModel] est nichée sous `patient`.
  Future<ResumePatient> obtenirResumePatient() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.monDossier);
      final data = response.data as Map<String, dynamic>;
      return ResumePatientModel.fromJson(data['patient'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  /// `GET /traitements` — le backend déduit automatiquement le patient
  /// depuis le compte connecté (aucun `patientId` à transmettre depuis
  /// l'app Patients/Familles).
  Future<List<Traitement>> obtenirTraitements() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.mesTraitements);
      final data = response.data as Map<String, dynamic>;
      return (data['traitements'] as List)
          .map((e) => TraitementModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  /// `GET /rapports` — ne renvoie que les rapports déjà validés par un
  /// médecin pour un compte patient (filtré côté serveur).
  Future<List<RapportJournalier>> obtenirRapports() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.mesRapports);
      final data = response.data as Map<String, dynamic>;
      return (data['rapports'] as List)
          .map((e) => RapportJournalierModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  Future<List<Appreciation>> obtenirAppreciations() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.mesAppreciations);
      final data = response.data as Map<String, dynamic>;
      return (data['appreciations'] as List)
          .map((e) => AppreciationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  /// UC7 "Noter les tâches quotidiennes réalisées par l'AVS".
  Future<void> noterAvs({required String rapportId, required int note, required String commentaire}) async {
    try {
      await _apiClient.dio.post(
        ApiConstants.mesAppreciations,
        data: {'rapportId': rapportId, 'note': note, 'commentaire': commentaire},
      );
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  Future<List<DocumentMedicalDossier>> obtenirDocuments() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.mesDocuments);
      final data = response.data as Map<String, dynamic>;
      return (data['documents'] as List)
          .map((e) => DocumentMedicalModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  /// `GET /rendezvous` — attention à la casse : le backend renvoie la clé
  /// `rendezVous` (V majuscule), pas `rendezvous`.
  Future<List<RendezVousDossier>> obtenirRendezVous() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.mesRendezVous);
      final data = response.data as Map<String, dynamic>;
      return (data['rendezVous'] as List)
          .map((e) => RendezVousModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }
}
