import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/mock/mock_backend.dart';
import '../../domain/entities/membre_famille.dart';

/// Servi par [MockBackend] tant que le vrai backend n'expose pas encore
/// `membresFamilleIds` côté patients (README section 6.4).
final membresFamilleProvider = FutureProvider.autoDispose<List<MembreFamille>>((ref) {
  return MockBackend.instance.obtenirMembresFamille();
});

class InviterMembreFamilleController extends StateNotifier<bool> {
  final Ref _ref;

  InviterMembreFamilleController(this._ref) : super(false);

  Future<bool> inviter({
    required String nom,
    required String prenom,
    required String lien,
    required String email,
  }) async {
    state = true;
    try {
      await MockBackend.instance.inviterMembreFamille(nom: nom, prenom: prenom, lien: lien, email: email);
      _ref.invalidate(membresFamilleProvider);
      return true;
    } finally {
      state = false;
    }
  }
}

final inviterMembreFamilleControllerProvider =
    StateNotifierProvider.autoDispose<InviterMembreFamilleController, bool>((ref) {
  return InviterMembreFamilleController(ref);
});
