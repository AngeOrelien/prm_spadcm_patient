import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../shared/services/api_client.dart';
import '../../domain/entities/messagerie_entities.dart';
import '../models/messagerie_models.dart';

/// Messagerie en mode "pull" (pas de Socket.io côté backend pour l'instant) :
/// chaque écran recharge via ces appels REST plutôt que de recevoir des
/// événements temps réel. La forme des méthodes reste prête pour un futur
/// remplacement par des événements socket.
class MessagerieRemoteDataSource {
  final ApiClient _apiClient;

  MessagerieRemoteDataSource(this._apiClient);

  Future<List<Conversation>> obtenirConversations() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.conversations);
      final data = response.data as Map<String, dynamic>;
      return (data['conversations'] as List)
          .map((e) => ConversationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  Future<List<MessageConversation>> obtenirMessages(String conversationId) async {
    try {
      final response = await _apiClient.dio.get('${ApiConstants.conversations}/$conversationId/messages');
      final data = response.data as Map<String, dynamic>;
      return (data['messages'] as List)
          .map((e) => MessageConversationModel.fromJson(e as Map<String, dynamic>))
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
}
