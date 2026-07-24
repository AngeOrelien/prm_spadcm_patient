import 'package:dio/dio.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../shared/mock/mock_api.dart';
import '../../../../shared/services/api_client.dart';
import '../../domain/entities/dossier_entities.dart';
import '../models/dossier_models.dart';

class DossierRemoteDataSource {
  final ApiClient _apiClient;

  DossierRemoteDataSource(this._apiClient);

  Future<ResumePatient> obtenirResumePatient() async {
    if (AppConfig.useMockBackend) {
      return ResumePatientModel.fromJson(await MockApi.patient());
    }
    try {
      final response = await _apiClient.dio.get(ApiConstants.monDossier);
      return ResumePatientModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  Future<List<Traitement>> obtenirTraitements() async {
    if (AppConfig.useMockBackend) {
      final data = await MockApi.traitements();
      return data.map(TraitementModel.fromJson).toList();
    }
    try {
      final response = await _apiClient.dio.get(ApiConstants.mesTraitements);
      return (response.data as List).map((e) => TraitementModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  Future<List<RapportJournalier>> obtenirRapports() async {
    if (AppConfig.useMockBackend) {
      final data = await MockApi.rapportsJournaliers();
      return data.map(RapportJournalierModel.fromJson).toList();
    }
    try {
      final response = await _apiClient.dio.get(ApiConstants.mesRapports);
      return (response.data as List)
          .map((e) => RapportJournalierModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  Future<List<Appreciation>> obtenirAppreciations() async {
    if (AppConfig.useMockBackend) {
      final data = await MockApi.appreciations();
      return data.map(AppreciationModel.fromJson).toList();
    }
    try {
      final response = await _apiClient.dio.get(ApiConstants.mesAppreciations);
      return (response.data as List).map((e) => AppreciationModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  /// UC7 "Noter les tâches quotidiennes réalisées par l'AVS".
  Future<void> noterAvs({required String rapportId, required int note, required String commentaire}) async {
    if (AppConfig.useMockBackend) {
      await MockApi.noterAvs(rapportId: rapportId, note: note, commentaire: commentaire);
      return;
    }
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
    if (AppConfig.useMockBackend) {
      final data = await MockApi.documentsMedicaux();
      return data.map(DocumentMedicalModel.fromJson).toList();
    }
    try {
      final response = await _apiClient.dio.get(ApiConstants.mesDocuments);
      return (response.data as List).map((e) => DocumentMedicalModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  Future<List<RendezVousDossier>> obtenirRendezVous() async {
    if (AppConfig.useMockBackend) {
      final data = await MockApi.rendezVous();
      return data.map(RendezVousModel.fromJson).toList();
    }
    try {
      final response = await _apiClient.dio.get(ApiConstants.mesRendezVous);
      return (response.data as List).map((e) => RendezVousModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }
}
