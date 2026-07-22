import '../../domain/entities/dashboard_entities.dart';

DateTime? _dateOrNull(dynamic value) => value == null ? null : DateTime.tryParse(value as String);

String? _nomComplet(Map? personne) {
  if (personne == null) return null;
  final prenom = personne['prenom'] as String? ?? '';
  final nom = personne['nom'] as String? ?? '';
  final complet = '$prenom $nom'.trim();
  return complet.isEmpty ? null : complet;
}

class ContactUrgenceModel {
  static ContactUrgence fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ContactUrgence();
    return ContactUrgence(
      nom: json['nom'] as String?,
      lien: json['lien'] as String?,
      telephone: json['telephone'] as String?,
    );
  }
}

class DossierPatientModel {
  static DossierPatient fromJson(Map<String, dynamic> json) {
    final medecin = json['medecinReferentId'];
    final medecinMap = medecin is Map ? medecin : null;

    return DossierPatient(
      id: (json['_id'] ?? json['id']).toString(),
      ficheNumero: json['ficheNumero'] as String?,
      nom: json['nom'] as String? ?? '',
      prenom: json['prenom'] as String? ?? '',
      age: json['age'] as int?,
      dateNaissance: _dateOrNull(json['dateNaissance']),
      ville: json['ville'] as String?,
      quartier: json['quartier'] as String?,
      adresse: json['adresse'] as String?,
      pathologie: json['pathologie'] as String?,
      antecedents: (json['antecedents'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      allergies: (json['allergies'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      contactUrgence: ContactUrgenceModel.fromJson(
        json['contactUrgence'] as Map<String, dynamic>?,
      ),
      photoUrl: json['photoUrl'] as String?,
      medecinReferentNom: _nomComplet(medecinMap),
      medecinReferentTelephone: medecinMap?['telephone'] as String?,
      medecinReferentSpecialite: medecinMap?['specialite'] as String?,
    );
  }
}

class AvsAssigneModel {
  static AvsAssigne? fromJson(dynamic json) {
    if (json == null || json is! Map) return null;
    return AvsAssigne(
      id: (json['_id'] ?? json['id']).toString(),
      nom: json['nom'] as String? ?? '',
      prenom: json['prenom'] as String? ?? '',
      telephone: json['telephone'] as String?,
      zoneAffectation: json['zoneAffectation'] as String?,
    );
  }
}

class ParametresVitauxModel {
  static ParametresVitaux fromJson(Map<String, dynamic> json) {
    return ParametresVitaux(
      moment: json['moment'] as String? ?? '',
      pouls: json['pouls'] as String?,
      taBrasDroit: json['taBrasDroit'] as String?,
      taBrasGauche: json['taBrasGauche'] as String?,
      temperature: json['temperature'] as String?,
      spo2: json['spo2'] as String?,
      glycemie: json['glycemie'] as String?,
    );
  }
}

class DernierRapportModel {
  static DernierRapport? fromJson(dynamic json) {
    if (json == null || json is! Map) return null;
    final avs = json['avsId'];
    final medecin = json['medecinValidateurId'];

    return DernierRapport(
      id: (json['_id'] ?? json['id']).toString(),
      date: _dateOrNull(json['date']) ?? DateTime.now(),
      avsNom: _nomComplet(avs is Map ? avs : null),
      medecinValidateurNom: _nomComplet(medecin is Map ? medecin : null),
      parametresVitaux: (json['parametresVitaux'] as List? ?? [])
          .map((e) => ParametresVitauxModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      soinsTaches: (json['soinsTaches'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      observations: json['observations'] as String?,
      conclusion: json['conclusion'] as String?,
      resumeIA: json['resumeIA'] as String?,
      valide: json['valide'] as bool? ?? false,
    );
  }
}

class TraitementActifModel {
  static TraitementActif fromJson(Map<String, dynamic> json) {
    return TraitementActif(
      id: (json['_id'] ?? json['id']).toString(),
      medicament: json['medicament'] as String? ?? '',
      dosage: json['dosage'] as String?,
      posologieMatin: json['posologieMatin'] as String?,
      posologieMidi: json['posologieMidi'] as String?,
      posologieSoir: json['posologieSoir'] as String?,
    );
  }
}

class ProchainRendezVousModel {
  static ProchainRendezVous? fromJson(dynamic json) {
    if (json == null || json is! Map) return null;
    final medecin = json['medecinId'];
    final medecinMap = medecin is Map ? medecin : null;

    return ProchainRendezVous(
      id: (json['_id'] ?? json['id']).toString(),
      date: _dateOrNull(json['date']) ?? DateTime.now(),
      motif: json['motif'] as String?,
      lieu: json['lieu'] as String?,
      medecinNom: _nomComplet(medecinMap),
      medecinSpecialite: medecinMap?['specialite'] as String?,
    );
  }
}

class AlerteOuverteModel {
  static AlerteOuverte fromJson(Map<String, dynamic> json) {
    return AlerteOuverte(
      id: (json['_id'] ?? json['id']).toString(),
      type: json['type'] as String? ?? 'sos',
      description: json['description'] as String?,
      statut: statutAlerteFromString(json['statut'] as String?),
      dateCreation: _dateOrNull(json['createdAt']) ?? DateTime.now(),
    );
  }
}

class DocumentRecentModel {
  static DocumentRecent fromJson(Map<String, dynamic> json) {
    return DocumentRecent(
      id: (json['_id'] ?? json['id']).toString(),
      type: json['type'] as String? ?? 'autre',
      nomFichier: json['nomFichier'] as String?,
      url: json['url'] as String? ?? '',
      dateAjout: _dateOrNull(json['createdAt']) ?? DateTime.now(),
    );
  }
}

class TableauDeBordModel {
  static TableauDeBord fromJson(Map<String, dynamic> json) {
    return TableauDeBord(
      patient: DossierPatientModel.fromJson(json['patient'] as Map<String, dynamic>),
      avsAssigne: AvsAssigneModel.fromJson(json['avsAssigne']),
      dernierRapport: DernierRapportModel.fromJson(json['dernierRapport']),
      traitementsActifs: (json['traitementsActifs'] as List? ?? [])
          .map((e) => TraitementActifModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      prochainRendezVous: ProchainRendezVousModel.fromJson(json['prochainRendezVous']),
      alertesOuvertes: (json['alertesOuvertes'] as List? ?? [])
          .map((e) => AlerteOuverteModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      documentsRecents: (json['documentsRecents'] as List? ?? [])
          .map((e) => DocumentRecentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      notificationsNonLues: json['notificationsNonLues'] as int? ?? 0,
    );
  }
}
