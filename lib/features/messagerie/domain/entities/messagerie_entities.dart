/// Espace Messagerie du patient (onglet 4), inspiré de l'espace messagerie
/// connecté de l'app Personnel (AVS) : fils de discussion dynamiques avec
/// l'AVS affecté, les médecins, les coordonnateurs et les administrateurs —
/// plus une action "Signaler une urgence" intégrée ici (remplace l'ancien
/// bouton flottant SOS, voir `messagerie_page.dart`).

class Conversation {
  final String id;
  final String? nom;
  final String? interlocuteurId;
  final String? interlocuteurNom;
  final String? interlocuteurRole;
  final String? dernierMessage;
  final DateTime? dernierMessageAt;

  const Conversation({
    required this.id,
    this.nom,
    this.interlocuteurId,
    this.interlocuteurNom,
    this.interlocuteurRole,
    this.dernierMessage,
    this.dernierMessageAt,
  });

  String get titre => nom ?? interlocuteurNom ?? 'Conversation';
}

class MessageConversation {
  final String id;
  final String conversationId;
  final String expediteurId;
  final String? expediteurNom;
  final String contenu;
  final DateTime dateEnvoi;
  final bool lu;

  const MessageConversation({
    required this.id,
    required this.conversationId,
    required this.expediteurId,
    this.expediteurNom,
    required this.contenu,
    required this.dateEnvoi,
    this.lu = true,
  });

  bool estDeMoi(String monId) => expediteurId == monId;
}

/// Une entrée d'annuaire du personnel (médecin, coordonnateur,
/// administrateur), utilisée pour démarrer une conversation depuis
/// `MessageriePage`. Champs volontairement limités (pas de téléphone/email)
/// — voir la restriction équivalente côté backend pour l'AVS.
class PersonnelAnnuaire {
  final String id;
  final String nom;
  final String prenom;
  final String role;
  final String? photoUrl;

  const PersonnelAnnuaire({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.role,
    this.photoUrl,
  });

  String get nomComplet => '$prenom $nom';
}
