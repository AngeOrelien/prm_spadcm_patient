/// Onglet 2 — Soins (UC2/UC3/UC4 du README) : recherche/catalogue de soins,
/// souscription, historique des paiements.

class SoinCatalogue {
  final String id;
  final String nom;
  final String description;
  final int prix;
  final String frequenceVisites;
  final List<String> prestationsIncluses;

  /// Image de couverture affichée sur la carte du catalogue (vitrine +
  /// onglet Soins). URL absolue déjà renvoyée telle quelle par le backend
  /// (`POST /soins/:id/media`), rien à reconstruire côté app.
  final String? imageCouverture;

  /// Images supplémentaires affichées sur l'écran de détail (galerie).
  final List<String> images;

  /// Courtes vidéos illustrant le soin (écran de détail).
  final List<String> videos;

  const SoinCatalogue({
    required this.id,
    required this.nom,
    required this.description,
    required this.prix,
    required this.frequenceVisites,
    this.prestationsIncluses = const [],
    this.imageCouverture,
    this.images = const [],
    this.videos = const [],
  });
}

enum StatutSouscription { active, expiree, annulee, resiliee, enAttentePaiement }

StatutSouscription statutSouscriptionFromString(String? value) {
  switch (value) {
    case 'expiree':
      return StatutSouscription.expiree;
    case 'annulee':
      return StatutSouscription.annulee;
    case 'resiliee':
      return StatutSouscription.resiliee;
    case 'en_attente_paiement':
      return StatutSouscription.enAttentePaiement;
    case 'active':
    default:
      return StatutSouscription.active;
  }
}

/// Infos santé/allergies/régime saisies au moment de souscrire (README
/// frontend §7.1) — transmises directement dans `POST /souscriptions` via
/// `patientInfo`, sans passer par un dossier `Patient` pré-créé : c'est le
/// backend qui crée ce dossier automatiquement à la confirmation du
/// paiement.
class PatientInfoSouscription {
  final String? nom;
  final String? prenom;
  final List<String> allergies;
  final String? informationsSante;
  final String? regimeAlimentaire;

  const PatientInfoSouscription({
    this.nom,
    this.prenom,
    this.allergies = const [],
    this.informationsSante,
    this.regimeAlimentaire,
  });

  Map<String, dynamic> toJson() {
    return {
      if (nom != null && nom!.trim().isNotEmpty) 'nom': nom!.trim(),
      if (prenom != null && prenom!.trim().isNotEmpty) 'prenom': prenom!.trim(),
      if (allergies.isNotEmpty) 'allergies': allergies,
      if (informationsSante != null && informationsSante!.trim().isNotEmpty)
        'informationsSante': informationsSante!.trim(),
      if (regimeAlimentaire != null && regimeAlimentaire!.trim().isNotEmpty)
        'regimeAlimentaire': regimeAlimentaire!.trim(),
    };
  }
}

class Souscription {
  final String id;
  final String? soinId;
  final String soinNom;
  final int soinPrix;
  final DateTime dateDebut;
  final DateTime? dateFin;
  final StatutSouscription statut;

  const Souscription({
    required this.id,
    this.soinId,
    required this.soinNom,
    required this.soinPrix,
    required this.dateDebut,
    this.dateFin,
    required this.statut,
  });

  /// Une souscription "bloque" une nouvelle souscription tant qu'elle n'est
  /// ni expirée, ni annulée, ni résiliée — même règle d'exclusivité que
  /// `STATUTS_BLOQUANTS` côté backend (`controllers/souscriptionController.js`).
  bool get estBloquante =>
      statut == StatutSouscription.active || statut == StatutSouscription.enAttentePaiement;
}

enum StatutPaiement { reussi, echoue, enAttente }

StatutPaiement statutPaiementFromString(String? value) {
  switch (value) {
    case 'echoue':
      return StatutPaiement.echoue;
    case 'en_attente':
      return StatutPaiement.enAttente;
    case 'reussi':
    default:
      return StatutPaiement.reussi;
  }
}

class Paiement {
  final String id;
  final int montant;
  final String devise;
  final StatutPaiement statut;
  final String referenceExterne;
  final DateTime dateTransaction;

  const Paiement({
    required this.id,
    required this.montant,
    required this.devise,
    required this.statut,
    required this.referenceExterne,
    required this.dateTransaction,
  });
}
