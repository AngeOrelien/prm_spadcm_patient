import 'dart:math';

import '../../core/config/app_config.dart';
import 'mock_db.dart';

/// Point d'entrée unique du mode mock, appelé par les datasources à la
/// place de [ApiClient] quand `AppConfig.useMockBackend == true`.
///
/// Chaque méthode renvoie exactement la forme de JSON qu'enverra plus tard
/// le vrai endpoint (mêmes clés `_id`, mêmes objets imbriqués) pour que les
/// `Model.fromJson(...)` existants n'aient rien à changer à la bascule.
class MockApi {
  MockApi._();

  static Future<T> _simulate<T>(T Function() build) async {
    await Future.delayed(AppConfig.mockLatency);
    return build();
  }

  // --- Auth ---

  static Future<Map<String, dynamic>> login({required String email, required String motDePasse}) {
    return _simulate(() => {
          'accessToken': 'mock-access-token',
          'refreshToken': 'mock-refresh-token',
          'utilisateur': MockDb.utilisateurConnecte,
        });
  }

  static Future<Map<String, dynamic>> profil() {
    return _simulate(() => {'utilisateur': MockDb.utilisateurConnecte});
  }

  // --- Tableau de bord (Accueil) ---

  static Future<Map<String, dynamic>> tableauDeBord() {
    return _simulate(() {
      final dernierRapportValide = MockDb.rapportsJournaliers.firstWhere(
        (r) => r['valide'] == true,
        orElse: () => MockDb.rapportsJournaliers.first,
      );
      final rdvAVenir = MockDb.rendezVous.where((r) => r['statut'] == 'planifie');
      return {
        'patient': MockDb.patient,
        'avsAssigne': MockDb.avsAssigne,
        'dernierRapport': dernierRapportValide,
        'traitementsActifs': MockDb.traitements.where((t) => t['statut'] == 'actif').toList(),
        'prochainRendezVous': rdvAVenir.isEmpty ? null : rdvAVenir.first,
        'alertesOuvertes': MockDb.alertes.where((a) => a['statut'] != 'resolue').toList(),
        'documentsRecents': MockDb.documentsMedicaux.take(3).toList(),
        'notificationsNonLues': MockDb.notificationsNonLues,
      };
    });
  }

  // --- Soins : catalogue, souscription, paiements ---

  static Future<List<Map<String, dynamic>>> catalogueSoins() {
    return _simulate(() => List<Map<String, dynamic>>.from(MockDb.soinsCatalogue));
  }

  static Future<List<Map<String, dynamic>>> souscriptions() {
    return _simulate(() => List<Map<String, dynamic>>.from(MockDb.souscriptions));
  }

  static Future<List<Map<String, dynamic>>> paiements() {
    return _simulate(() {
      final liste = List<Map<String, dynamic>>.from(MockDb.paiements);
      liste.sort((a, b) => (b['dateTransaction'] as String).compareTo(a['dateTransaction'] as String));
      return liste;
    });
  }

  /// Simule `POST /souscriptions` + `POST /paiements` + webhook de
  /// confirmation : crée le paiement, la souscription, et si le patient
  /// n'a pas encore de dossier actif, le "planning" est considéré généré.
  static Future<Map<String, dynamic>> souscrire({required String soinId}) {
    return _simulate(() {
      final soin = MockDb.soinsCatalogue.firstWhere((s) => s['_id'] == soinId);
      final paiement = {
        '_id': MockDb.nextId('pai'),
        'montant': soin['prix'],
        'devise': 'XAF',
        'statut': 'reussi',
        'referenceExterne': 'MOMO-${Random().nextInt(89999999) + 10000000}',
        'dateTransaction': DateTime.now().toIso8601String(),
      };
      final souscription = {
        '_id': MockDb.nextId('sou'),
        'soinId': soin,
        'paiementId': paiement['_id'],
        'dateDebut': DateTime.now().toIso8601String(),
        'dateFin': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        'statut': 'active',
      };
      // La nouvelle souscription devient la référence active.
      MockDb.souscriptions
        ..clear()
        ..add(souscription);
      MockDb.paiements.insert(0, paiement);
      return {'souscription': souscription, 'paiement': paiement};
    });
  }

  // --- Dossier médical : traitements, rapports, documents, RDV ---

  static Future<Map<String, dynamic>> patient() => _simulate(() => MockDb.patient);

  static Future<List<Map<String, dynamic>>> traitements() {
    return _simulate(() => List<Map<String, dynamic>>.from(MockDb.traitements));
  }

  static Future<List<Map<String, dynamic>>> rapportsJournaliers() {
    return _simulate(() {
      final liste = List<Map<String, dynamic>>.from(MockDb.rapportsJournaliers);
      liste.sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));
      return liste;
    });
  }

  static Future<List<Map<String, dynamic>>> appreciations() {
    return _simulate(() => List<Map<String, dynamic>>.from(MockDb.appreciations));
  }

  /// UC7 "Noter les tâches quotidiennes réalisées par l'AVS".
  static Future<Map<String, dynamic>> noterAvs({
    required String rapportId,
    required int note,
    required String commentaire,
  }) {
    return _simulate(() {
      final appreciation = {
        '_id': MockDb.nextId('app'),
        'rapportId': rapportId,
        'avsId': MockDb.avsAssigne['_id'],
        'note': note,
        'commentaire': commentaire,
        'dateCreation': DateTime.now().toIso8601String(),
      };
      MockDb.appreciations.insert(0, appreciation);
      return appreciation;
    });
  }

  static Future<List<Map<String, dynamic>>> documentsMedicaux() {
    return _simulate(() => List<Map<String, dynamic>>.from(MockDb.documentsMedicaux));
  }

  static Future<List<Map<String, dynamic>>> rendezVous() {
    return _simulate(() {
      final liste = List<Map<String, dynamic>>.from(MockDb.rendezVous);
      liste.sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
      return liste;
    });
  }

  // --- Messagerie ---

  static Future<List<Map<String, dynamic>>> conversations() {
    return _simulate(() => List<Map<String, dynamic>>.from(MockDb.conversations));
  }

  static Future<List<Map<String, dynamic>>> messages(String conversationId) {
    return _simulate(() {
      final liste = MockDb.messages.where((m) => m['conversationId'] == conversationId).toList();
      liste.sort((a, b) => (a['dateEnvoi'] as String).compareTo(b['dateEnvoi'] as String));
      return liste;
    });
  }

  static Future<Map<String, dynamic>> envoyerMessage({
    required String conversationId,
    required String contenu,
  }) {
    return _simulate(() {
      final message = {
        '_id': MockDb.nextId('msg'),
        'conversationId': conversationId,
        'expediteurId': MockDb.utilisateurConnecte['id'],
        'contenu': contenu,
        'lu': true,
        'dateEnvoi': DateTime.now().toIso8601String(),
      };
      MockDb.messages.add(message);
      return message;
    });
  }

  /// Marque comme lus tous les messages d'un fil (ouverture de la
  /// conversation), pour que le badge de notifications se mette à jour.
  static Future<void> marquerConversationLue(String conversationId) {
    return _simulate(() {
      for (final m in MockDb.messages) {
        if (m['conversationId'] == conversationId) m['lu'] = true;
      }
    });
  }

  // --- Compte famille (Profil) ---

  static Future<List<Map<String, dynamic>>> membresFamille() {
    return _simulate(() => List<Map<String, dynamic>>.from(MockDb.membresFamille));
  }

  static Future<Map<String, dynamic>> inviterMembreFamille({
    required String nom,
    required String prenom,
    required String lien,
    required String email,
  }) {
    return _simulate(() {
      final membre = {
        'id': MockDb.nextId('user'),
        'nom': nom,
        'prenom': prenom,
        'lien': lien,
        'email': email,
        'telephone': '',
        'estCompteConnecte': false,
      };
      MockDb.membresFamille.add(membre);
      return membre;
    });
  }

  static Future<void> definirBiometrie(bool active) {
    return _simulate(() => MockDb.utilisateurConnecte['biometrieActive'] = active);
  }

  // --- Alerte SOS ---

  static Future<Map<String, dynamic>> declencherAlerte({String? description}) {
    return _simulate(() {
      final alerte = {
        '_id': MockDb.nextId('alerte'),
        'patientId': MockDb.patient['_id'],
        'declencheurId': MockDb.utilisateurConnecte['id'],
        'type': 'sos',
        'description': description ?? '',
        'statut': 'ouverte',
        'createdAt': DateTime.now().toIso8601String(),
      };
      MockDb.alertes.insert(0, alerte);
      return alerte;
    });
  }
}
