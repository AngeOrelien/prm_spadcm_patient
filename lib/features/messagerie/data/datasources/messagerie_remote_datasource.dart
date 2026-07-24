import 'package:dio/dio.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../shared/mock/mock_api.dart';
import '../../../../shared/services/api_client.dart';
import '../../domain/entities/messagerie_entities.dart';
import '../models/messagerie_models.dart';

/// Tant que Socket.io n'est pas branché côté backend (Phase 4 de la feuille
/// de route), la messagerie fonctionne en mode "pull" via [MockApi] :
/// chaque envoi ajoute le message localement, sans temps réel entre
/// appareils. La forme des méthodes est déjà prête pour un futur
/// remplacement par des événements socket.
class MessagerieRemoteDataSource {
  final ApiClient _apiClient;

  MessagerieRemoteDataSource(this._apiClient);

  Future<List<Conversation>> obtenirConversations() async {
    if (AppConfig.useMockBackend) {
      final data = await MockApi.conversations();
      return data.map(ConversationModel.fromJson).toList();
    }
    try {
      final response = await _apiClient.dio.get(ApiConstants.conversations);
      return (response.data as List).map((e) => ConversationModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  Future<List<MessageConversation>> obtenirMessages(String conversationId) async {
    if (AppConfig.useMockBackend) {
      final data = await MockApi.messages(conversationId);
      return data.map(MessageConversationModel.fromJson).toList();
    }
    try {
      final response = await _apiClient.dio.get('${ApiConstants.conversations}/$conversationId/messages');
      return (response.data as List)
          .map((e) => MessageConversationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  Future<void> envoyerMessage({required String conversationId, required String contenu}) async {
    if (AppConfig.useMockBackend) {
      await MockApi.envoyerMessage(conversationId: conversationId, contenu: contenu);
      return;
    }
    try {
      await _apiClient.dio.post(
        '${ApiConstants.conversations}/$conversationId/messages',
        data: {'contenu': contenu},
      );
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  Future<void> marquerLue(String conversationId) async {
    if (AppConfig.useMockBackend) {
      await MockApi.marquerConversationLue(conversationId);
      return;
    }
    try {
      await _apiClient.dio.post('${ApiConstants.conversations}/$conversationId/lu');
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }
}
