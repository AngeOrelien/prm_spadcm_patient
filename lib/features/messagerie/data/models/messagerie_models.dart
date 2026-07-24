import '../../domain/entities/messagerie_entities.dart';

class ConversationModel {
  static Conversation fromJson(Map<String, dynamic> json) {
    final interlocuteur = json['interlocuteur'];
    final interlocuteurMap = interlocuteur is Map ? interlocuteur : null;
    return Conversation(
      id: (json['_id'] ?? json['id']).toString(),
      type: typeConversationFromString(json['type'] as String?),
      titre: json['titre'] as String? ?? 'Conversation',
      interlocuteurTelephone: interlocuteurMap?['telephone'] as String?,
    );
  }
}

class MessageConversationModel {
  static MessageConversation fromJson(Map<String, dynamic> json) {
    return MessageConversation(
      id: (json['_id'] ?? json['id']).toString(),
      conversationId: (json['conversationId'] ?? '').toString(),
      expediteurId: (json['expediteurId'] ?? '').toString(),
      contenu: json['contenu'] as String? ?? '',
      lu: json['lu'] as bool? ?? false,
      dateEnvoi: DateTime.tryParse(json['dateEnvoi'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
