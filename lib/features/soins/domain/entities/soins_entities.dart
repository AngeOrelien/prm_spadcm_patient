/// Onglet 2 — Soins (UC2/UC3/UC4 du README) : recherche/catalogue de soins,
/// souscription, historique des paiements.

class SoinCatalogue {
  final String id;
  final String nom;
  final String description;
  final int prix;
  final String frequenceVisites;
  final List<String> prestationsIncluses;

  const SoinCatalogue({
    required this.id,
    required this.nom,
    required this.description,
    required this.prix,
    required this.frequenceVisites,
    this.prestationsIncluses = const [],
  });
}

enum StatutSouscription { active, expiree, annulee }

StatutSouscription statutSouscriptionFromString(String? value) {
  switch (value) {
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
  final String soinNom;
  final int soinPrix;
  final DateTime dateDebut;
  final DateTime? dateFin;
  final StatutSouscription statut;

  const Souscription({
    required this.id,
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
