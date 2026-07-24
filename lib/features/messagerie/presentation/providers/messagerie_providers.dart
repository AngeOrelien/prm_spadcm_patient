import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/messagerie_remote_datasource.dart';
import '../../domain/entities/messagerie_entities.dart';

final messagerieRemoteDataSourceProvider = Provider<MessagerieRemoteDataSource>((ref) {
  return MessagerieRemoteDataSource(ref.watch(apiClientProvider));
});

final conversationsProvider = FutureProvider.autoDispose<List<Conversation>>((ref) {
  return ref.watch(messagerieRemoteDataSourceProvider).obtenirConversations();
});

/// Un provider par fil de discussion (paramétré par l'id de conversation),
/// pour que l'écran de chat garde son propre état indépendamment de la
/// liste des conversations.
final messagesProvider = FutureProvider.autoDispose.family<List<MessageConversation>, String>((ref, conversationId) {
  return ref.watch(messagerieRemoteDataSourceProvider).obtenirMessages(conversationId);
});

class EnvoiMessageController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> envoyer({required String conversationId, required String contenu}) async {
    if (contenu.trim().isEmpty) return false;
    state = const AsyncLoading();
    try {
      await ref.read(messagerieRemoteDataSourceProvider).envoyerMessage(
            conversationId: conversationId,
            contenu: contenu.trim(),
          );
      ref.invalidate(messagesProvider(conversationId));
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<void> marquerLue(String conversationId) async {
    await ref.read(messagerieRemoteDataSourceProvider).marquerLue(conversationId);
    ref.invalidate(conversationsProvider);
  }
}

final envoiMessageControllerProvider = AsyncNotifierProvider<EnvoiMessageController, void>(
  EnvoiMessageController.new,
);
