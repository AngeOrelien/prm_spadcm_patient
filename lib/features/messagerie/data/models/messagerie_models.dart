import '../../domain/entities/messagerie_entities.dart';

String _idDe(dynamic valeur) {
  if (valeur == null) return '';
  if (valeur is Map) return (valeur['_id'] ?? valeur['id'] ?? '').toString();
  return valeur.toString();
}

String? _nomCompletDepuis(dynamic valeur) {
  if (valeur is Map) {
    final nom = valeur['nom'] ?? '';
    final prenom = valeur['prenom'] ?? '';
    final complet = '$prenom $nom'.trim();
    return complet.isEmpty ? null : complet;
  }
  return null;
}

/// Mapping `Conversation` (voir `messagerieController.js`). [currentUserId]
/// sert à déterminer qui est "l'autre" participant (celui à afficher comme
/// interlocuteur dans la liste des fils de discussion) — même logique que
/// côté app Personnel (`ConversationModel`).
class ConversationModel {
  static Conversation fromJson(Map<String, dynamic> json, String currentUserId) {
    final participants = (json['participantsIds'] as List?) ?? const [];
    Map? autre;
    for (final p in participants) {
      if (p is Map && _idDe(p) != currentUserId) {
        autre = p;
        break;
      }
    }

    return Conversation(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      nom: json['nom'] as String?,
      interlocuteurId: autre != null ? _idDe(autre) : null,
      interlocuteurNom: autre != null ? _nomCompletDepuis(autre) : null,
      interlocuteurRole: autre != null ? autre['role']?.toString() : null,
      dernierMessage: json['dernierMessage'] as String?,
      dernierMessageAt:
          json['dernierMessageAt'] != null ? DateTime.tryParse(json['dernierMessageAt'].toString()) : null,
    );
  }
}

/// Mapping `Message` (voir `messagerieController.js`).
class MessageConversationModel {
  static MessageConversation fromJson(Map<String, dynamic> json, String currentUserId) {
    final expediteur = json['expediteurId'];
    final expediteurId = _idDe(expediteur);
    final luParIds = (json['luParIds'] as List?)?.map((e) => _idDe(e)).toList() ?? const [];
    return MessageConversation(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      conversationId: _idDe(json['conversationId']),
      expediteurId: expediteurId,
      expediteurNom: _nomCompletDepuis(expediteur),
      contenu: json['contenu'] as String? ?? '',
      dateEnvoi: DateTime.tryParse('${json['createdAt']}') ?? DateTime.now(),
      lu: luParIds.contains(currentUserId) || expediteurId == currentUserId,
    );
  }
}

class PersonnelAnnuaireModel {
  static PersonnelAnnuaire fromJson(Map<String, dynamic> json) {
    return PersonnelAnnuaire(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      nom: json['nom'] as String? ?? '',
      prenom: json['prenom'] as String? ?? '',
      role: json['role']?.toString() ?? '',
      photoUrl: json['photoUrl'] as String?,
    );
  }
}
