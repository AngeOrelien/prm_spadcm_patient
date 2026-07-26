/// Onglet 2 — Soins (UC2/UC3/UC4 du README) : recherche/catalogue de soins,
/// souscription, historique des paiements.

class SoinCatalogue {
  final String id;
  final String nom;
  final String description;
  final int prix;
  final String frequenceVisites;
  final List<String> prestationsIncluses;

  /// URL absolue de l'image de couverture (ex:
  /// `http://localhost:4000/uploads/soins/<id>/....jpg`), renvoyée telle
  /// quelle par le backend. `null` si le soin n'a pas encore de média.
  final String? imageCouverture;

  /// Galerie d'images complémentaires (URLs absolues), vide si aucune.
  final List<String> images;

  /// Courtes vidéos illustrant le soin (URLs absolues), vide si aucune.
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

/// Informations médicales saisies au moment de la souscription (README
/// section 0 : plus de dossier `Patient` séparé à créer avant paiement, ce
/// formulaire remplace l'ancien écran "compléter mon dossier").
class PatientInfoSouscription {
  final List<String> allergies;
  final String? informationsSante;
  final String? regimeAlimentaire;
  final String? nom;
  final String? prenom;

  const PatientInfoSouscription({
    this.allergies = const [],
    this.informationsSante,
    this.regimeAlimentaire,
    this.nom,
    this.prenom,
  });

  Map<String, dynamic> toJson() {
    return {
      if (allergies.isNotEmpty) 'allergies': allergies,
      if (informationsSante != null && informationsSante!.trim().isNotEmpty)
        'informationsSante': informationsSante!.trim(),
      if (regimeAlimentaire != null && regimeAlimentaire!.trim().isNotEmpty)
        'regimeAlimentaire': regimeAlimentaire!.trim(),
      if (nom != null && nom!.trim().isNotEmpty) 'nom': nom!.trim(),
      if (prenom != null && prenom!.trim().isNotEmpty) 'prenom': prenom!.trim(),
    };
  }
}

enum StatutSouscription { active, enAttentePaiement, expiree, annulee }

StatutSouscription statutSouscriptionFromString(String? value) {
  switch (value) {
    case 'en_attente_paiement':
      return StatutSouscription.enAttentePaiement;
    case 'expiree':
      return StatutSouscription.expiree;
    case 'annulee':
      return StatutSouscription.annulee;
    case 'active':
    default:
      return StatutSouscription.active;
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
