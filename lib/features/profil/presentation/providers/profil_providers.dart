import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/profil_remote_datasource.dart';
import '../../domain/entities/profil_entities.dart';

final profilRemoteDataSourceProvider = Provider<ProfilRemoteDataSource>((ref) {
  return ProfilRemoteDataSource(ref.watch(apiClientProvider));
});

final membresFamilleProvider = FutureProvider.autoDispose<List<MembreFamille>>((ref) {
  return ref.watch(profilRemoteDataSourceProvider).obtenirMembresFamille();
});

/// État local (in-memory) de la biométrie. Un simple [Notifier] suffit :
/// la préférence est propre à l'appareil, pas besoin d'AsyncNotifier avec
/// état de chargement dédié. Désactivée par défaut tant que l'utilisateur
/// ne l'a pas explicitement activée dans Profil > Sécurité.
class BiometrieActiveNotifier extends Notifier<bool> {
  @override
  bool build() => false;
}

final biometrieActiveProvider = NotifierProvider<BiometrieActiveNotifier, bool>(
  BiometrieActiveNotifier.new,
);

class InvitationMembreController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> inviter({required String nom, required String prenom, required String lien, required String email}) async {
    state = const AsyncLoading();
    try {
      await ref.read(profilRemoteDataSourceProvider).inviterMembreFamille(
            nom: nom,
            prenom: prenom,
            lien: lien,
            email: email,
          );
      ref.invalidate(membresFamilleProvider);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final invitationMembreControllerProvider = AsyncNotifierProvider<InvitationMembreController, void>(
  InvitationMembreController.new,
);
