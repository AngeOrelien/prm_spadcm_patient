import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../shared/services/api_client.dart';
import '../../domain/entities/profil_entities.dart';

class ProfilRemoteDataSource {
  final ApiClient _apiClient;

  ProfilRemoteDataSource(this._apiClient);

  /// `GET /patients/moi/membres-famille` renvoie `{ success, resultats,
  /// membres: [...] }`, chaque membre étant un `Utilisateur` peuplé
  /// (nom/prenom/email/telephone).
  ///
  /// ⚠️ Limitation actuelle du backend : il n'existe pas encore de champ
  /// "lien de parenté" par membre (ex: "Fils", "Épouse") en base — `lien`
  /// est donc renvoyé vide pour l'instant. Ajouter ce champ nécessiterait de
  /// transformer `Patient.membresFamilleIds` (simple tableau d'ID) en un
  /// tableau de sous-documents `{ utilisateurId, lien }` côté backend.
  Future<List<MembreFamille>> obtenirMembresFamille() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.membresFamille);
      final data = response.data as Map<String, dynamic>;
      return (data['membres'] as List)
          .map((e) => MembreFamille(
                id: (e['_id'] ?? e['id']).toString(),
                nom: e['nom'] as String? ?? '',
                prenom: e['prenom'] as String? ?? '',
                lien: e['lien'] as String? ?? '',
                email: e['email'] as String? ?? '',
                telephone: e['telephone'] as String?,
                estCompteConnecte: false,
              ))
          .toList();
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  /// ⚠️ PAS ENCORE SUPPORTÉ CÔTÉ BACKEND.
  ///
  /// Le backend ne sait aujourd'hui que lier un compte **existant** de
  /// l'app Patients/Familles (`POST /patients/:id/membres-famille` avec un
  /// `utilisateurId`) — il n'y a pas de flux d'invitation par email pour
  /// créer un nouveau compte. Appeler cette méthode lève donc une erreur
  /// explicite plutôt que d'appeler un endpoint qui n'existe pas ou de
  /// simuler un succès trompeur.
  ///
  /// Pour activer réellement cette fonctionnalité, il faudra soit :
  /// - ajouter côté backend un flux d'invitation (créer un compte
  ///   `role: 'patient'` + email d'invitation + lien automatique), soit
  /// - adapter cet écran pour ne proposer que "lier un compte existant"
  ///   (demander l'ID ou l'email d'un compte déjà créé, puis résoudre son
  ///   `utilisateurId` avant d'appeler `POST /patients/:id/membres-famille`).
  Future<void> inviterMembreFamille({
    required String nom,
    required String prenom,
    required String lien,
    required String email,
  }) async {
    throw const AppException(
      "L'invitation d'un nouveau membre par email n'est pas encore disponible. "
      'Un administrateur peut lier un compte déjà existant depuis son espace.',
    );
  }

  Future<void> definirBiometrie(bool active) async {
    try {
      await _apiClient.dio.patch(ApiConstants.me, data: {'biometrieActive': active});
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }
}
