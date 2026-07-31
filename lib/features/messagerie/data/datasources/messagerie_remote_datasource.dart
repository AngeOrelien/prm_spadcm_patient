import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../shared/services/api_client.dart';
import '../../domain/entities/messagerie_entities.dart';
import '../models/messagerie_models.dart';

/// Messagerie en mode "pull" (pas de Socket.io côté backend pour l'instant) :
/// chaque écran recharge via ces appels REST plutôt que de recevoir des
/// événements temps réel.
class MessagerieRemoteDataSource {
  final ApiClient _apiClient;

  MessagerieRemoteDataSource(this._apiClient);

  Future<List<Conversation>> obtenirConversations(String currentUserId) async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.conversations);
      final data = response.data as Map<String, dynamic>;
      return (data['conversations'] as List)
          .map((e) => ConversationModel.fromJson(e as Map<String, dynamic>, currentUserId))
          .toList();
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  Future<List<MessageConversation>> obtenirMessages(String conversationId, String currentUserId) async {
    try {
      final response = await _apiClient.dio.get('${ApiConstants.conversations}/$conversationId/messages');
      final data = response.data as Map<String, dynamic>;
      return (data['messages'] as List)
          .map((e) => MessageConversationModel.fromJson(e as Map<String, dynamic>, currentUserId))
          .toList();
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  Future<void> envoyerMessage({required String conversationId, required String contenu}) async {
    try {
      await _apiClient.dio.post(
        '${ApiConstants.conversations}/$conversationId/messages',
        data: {'contenu': contenu},
      );
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  /// ⚠️ `PATCH .../:id/marquer-lu` (pas `POST .../:id/lu`, qui n'existe pas
  /// côté backend).
  Future<void> marquerLue(String conversationId) async {
    try {
      await _apiClient.dio.patch('${ApiConstants.conversations}/$conversationId/marquer-lu');
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  /// `POST /conversations` avec un seul participant en plus de soi : crée
  /// (ou récupère, le backend est idempotent pour une conversation privée à
  /// 2) le fil de discussion avec cet interlocuteur.
  Future<Conversation> creerOuObtenirConversation(String participantId, String currentUserId) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.conversations,
        data: {
          'participantsIds': [participantId],
          'type': 'privee',
        },
      );
      final data = response.data as Map<String, dynamic>;
      return ConversationModel.fromJson(data['conversation'] as Map<String, dynamic>, currentUserId);
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  /// `GET /utilisateurs/role/:role` — annuaire médecin/coordonnateur/
  /// administrateur, ouvert au patient côté backend (voir
  /// TODO-BACKEND.md). En cas d'échec (droit pas encore ouvert sur un
  /// environnement pas à jour), on absorbe l'erreur en liste vide plutôt
  /// que de casser tout l'onglet Messages pour une section.
  Future<List<PersonnelAnnuaire>> listerPersonnelParRole(String role) async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.utilisateursParRole(role));
      final data = (response.data['utilisateurs'] ?? response.data['data'] ?? const []) as List;
      return data.map((json) => PersonnelAnnuaireModel.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException {
      return const [];
    }
  }
}
