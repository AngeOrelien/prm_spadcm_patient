/// Onglet 4 — Messages (section 7.1 README) : deux fils distincts,
/// Administration et AVS assigné.

enum TypeConversation { administration, avs }

TypeConversation typeConversationFromString(String? value) {
  return value == 'avs' ? TypeConversation.avs : TypeConversation.administration;
}

class Conversation {
  final String id;
  final TypeConversation type;
  final String titre;
  final String? interlocuteurTelephone;

  const Conversation({
    required this.id,
    required this.type,
    required this.titre,
    this.interlocuteurTelephone,
  });
}

class MessageConversation {
  final String id;
  final String conversationId;
  final String expediteurId;
  final String contenu;
  final bool lu;
  final DateTime dateEnvoi;

  const MessageConversation({
    required this.id,
    required this.conversationId,
    required this.expediteurId,
    required this.contenu,
    required this.lu,
    required this.dateEnvoi,
  });

  bool estDeMoi(String monId) => expediteurId == monId;
}
