import '../../domain/entities/soins_entities.dart';

DateTime _dateOrNow(dynamic value) =>
    value == null ? DateTime.now() : DateTime.tryParse(value as String) ?? DateTime.now();

class SoinCatalogueModel {
  static SoinCatalogue fromJson(Map<String, dynamic> json) {
    return SoinCatalogue(
      id: (json['_id'] ?? json['id']).toString(),
      nom: json['nom'] as String? ?? '',
      description: json['description'] as String? ?? '',
      prix: (json['prix'] as num?)?.toInt() ?? 0,
      frequenceVisites: json['frequenceVisites'] as String? ?? '',
      prestationsIncluses: (json['prestationsIncluses'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      imageCouverture: json['imageCouverture'] as String?,
      images: (json['images'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      videos: (json['videos'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }
}

class SouscriptionModel {
  static Souscription fromJson(Map<String, dynamic> json) {
    final soin = json['soinId'];
    final soinMap = soin is Map ? soin : const {};
    // `soinId` peut être un id brut (String) si le backend ne l'a pas
    // "populate", ou l'objet soin complet une fois peuplé — on gère les deux.
    final soinIdValeur = soin is Map ? (soin['_id'] ?? soin['id']) : soin;
    return Souscription(
      id: (json['_id'] ?? json['id']).toString(),
      soinId: soinIdValeur?.toString(),
      soinNom: soinMap['nom'] as String? ?? 'Soin SPAD Cameroun',
      soinPrix: (soinMap['prix'] as num?)?.toInt() ?? 0,
      dateDebut: _dateOrNow(json['dateDebut']),
      dateFin: json['dateFin'] == null ? null : DateTime.tryParse(json['dateFin'] as String),
      statut: statutSouscriptionFromString(json['statut'] as String?),
    );
  }
}

class PaiementModel {
  static Paiement fromJson(Map<String, dynamic> json) {
    return Paiement(
      id: (json['_id'] ?? json['id']).toString(),
      montant: (json['montant'] as num?)?.toInt() ?? 0,
      devise: json['devise'] as String? ?? 'XAF',
      statut: statutPaiementFromString(json['statut'] as String?),
      referenceExterne: json['referenceExterne'] as String? ?? '',
      dateTransaction: _dateOrNow(json['dateTransaction']),
    );
  }
}
