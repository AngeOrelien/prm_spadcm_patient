import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../dashboard/domain/entities/dashboard_entities.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../data/datasources/messagerie_remote_datasource.dart';
import '../../domain/entities/messagerie_entities.dart';

final messagerieRemoteDataSourceProvider = Provider<MessagerieRemoteDataSource>((ref) {
  return MessagerieRemoteDataSource(ref.watch(apiClientProvider));
});

String? _monId(Ref ref) => ref.watch(authControllerProvider).value?.id;

final conversationsProvider = FutureProvider.autoDispose<List<Conversation>>((ref) {
  final monId = _monId(ref) ?? '';
  return ref.watch(messagerieRemoteDataSourceProvider).obtenirConversations(monId);
});

/// Un provider par fil de discussion (paramétré par l'id de conversation),
/// pour que l'écran de chat garde son propre état indépendamment de la
/// liste des conversations.
final messagesProvider = FutureProvider.autoDispose.family<List<MessageConversation>, String>((ref, conversationId) {
  final monId = _monId(ref) ?? '';
  return ref.watch(messagerieRemoteDataSourceProvider).obtenirMessages(conversationId, monId);
});

/// Annuaire du personnel par rôle (médecin/coordonnateur/administrateur),
/// utilisé par les sections de contacts de `MessageriePage` — même pattern
/// que côté app Personnel (`personnelAnnuaireProvider`).
final personnelAnnuaireProvider = FutureProvider.autoDispose.family<List<PersonnelAnnuaire>, String>((ref, role) {
  return ref.watch(messagerieRemoteDataSourceProvider).listerPersonnelParRole(role);
});

/// L'AVS actuellement affecté au patient (README §1) — dérivé du tableau de
/// bord plutôt que d'un annuaire général : un patient ne doit voir/écrire
/// qu'à SON AVS, pas au roster complet des AVS de SPAD Cameroun.
final avsAssigneMessagerieProvider = Provider.autoDispose<AsyncValue<AvsAssigne?>>((ref) {
  final tableau = ref.watch(tableauDeBordProvider);
  return tableau.whenData((t) => t.avsAssigne);
});

class MessagerieActions {
  final Ref _ref;

  MessagerieActions(this._ref);

  Future<Conversation> ouvrirConversationAvec(String participantId) {
    final monId = _monId(_ref) ?? '';
    return _ref.read(messagerieRemoteDataSourceProvider).creerOuObtenirConversation(participantId, monId);
  }
}

final messagerieActionsProvider = Provider<MessagerieActions>((ref) => MessagerieActions(ref));

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
      ref.invalidate(conversationsProvider);
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
