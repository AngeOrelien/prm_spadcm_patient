import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/contact_remote_datasource.dart';

final contactRemoteDataSourceProvider = Provider<ContactRemoteDataSource>((ref) {
  return ContactRemoteDataSource(ref.watch(apiClientProvider));
});

/// Contrôleur d'envoi du formulaire de contact public (état
/// loading/succès/erreur, y compris le cas `429` anti-spam — voir
/// `ApiException.isRateLimited`).
class ContactController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> envoyer({
    required String nom,
    String? email,
    String? telephone,
    required String sujet,
    required String message,
  }) async {
    state = const AsyncLoading();
    try {
      await ref.read(contactRemoteDataSourceProvider).envoyerMessage(
            nom: nom,
            email: email,
            telephone: telephone,
            sujet: sujet,
            message: message,
          );
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final contactControllerProvider = AsyncNotifierProvider<ContactController, void>(
  ContactController.new,
);
