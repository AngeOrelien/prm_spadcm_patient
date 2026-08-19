import '../../domain/entities/dossier_entities.dart';

DateTime? _dateOrNull(dynamic value) => value == null ? null : DateTime.tryParse(value as String);
DateTime _dateOrNow(dynamic value) => _dateOrNull(value) ?? DateTime.now();

class ResumePatientModel {
  /// [avsJson] correspond à `avsAssigne` dans la réponse de
  /// `GET /patients/moi` — un objet frère de `patient` (pas imbriqué dedans),
  /// donc transmis séparément par [DossierRemoteDataSource.obtenirResumePatient].
  static ResumePatient fromJson(Map<String, dynamic> json, {Map<String, dynamic>? avsJson}) {
    final contact = json['contactUrgence'] as Map<String, dynamic>?;
    final avsNom = avsJson == null ? null : '${avsJson['prenom'] ?? ''} ${avsJson['nom'] ?? ''}'.trim();
    return ResumePatient(
      nom: json['nom'] as String? ?? '',
      prenom: json['prenom'] as String? ?? '',
      ficheNumero: json['ficheNumero'] as String?,
      dateNaissance: _dateOrNull(json['dateNaissance']),
      ville: json['ville'] as String?,
      quartier: json['quartier'] as String?,
      antecedents: (json['antecedents'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      allergies: (json['allergies'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      difficultesMobilite: (json['difficultesMobilite'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      contactUrgence: contact == null
          ? null
          : ContactUrgenceDossier(
              nom: contact['nom'] as String?,
              lien: contact['lien'] as String?,
              telephone: contact['telephone'] as String?,
            ),
      avsNom: (avsNom == null || avsNom.isEmpty) ? null : avsNom,
    );
  }
}

class TraitementModel {
  static Traitement fromJson(Map<String, dynamic> json) {
    return Traitement(
      id: (json['_id'] ?? json['id']).toString(),
      medicament: json['medicament'] as String? ?? '',
      dosage: json['dosage'] as String?,
      posologieMatin: json['posologieMatin'] as String?,
      posologieMidi: json['posologieMidi'] as String?,
      posologieSoir: json['posologieSoir'] as String?,
      statut: json['statut'] as String? ?? 'actif',
    );
  }
}

class RapportJournalierModel {
  static RapportJournalier fromJson(Map<String, dynamic> json) {
    final avs = json['avsId'];
    final avsMap = avs is Map ? avs : null;
    return RapportJournalier(
      id: (json['_id'] ?? json['id']).toString(),
      date: _dateOrNow(json['date']),
      avsNom: avsMap == null ? null : '${avsMap['prenom'] ?? ''} ${avsMap['nom'] ?? ''}'.trim(),
      parametresVitaux: (json['parametresVitaux'] as List? ?? [])
          .map((e) => ParametresVitauxDossier(
                moment: (e as Map)['moment'] as String? ?? '',
                pouls: e['pouls'] as String?,
                taBrasDroit: e['taBrasDroit'] as String?,
                taBrasGauche: e['taBrasGauche'] as String?,
                temperature: e['temperature'] as String?,
                spo2: e['spo2'] as String?,
                glycemie: e['glycemie'] as String?,
              ))
          .toList(),
      soinsTaches: (json['soinsTaches'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      activites: (json['activites'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      visites: (json['visites'] as List? ?? [])
          .map((e) => VisiteRecue(
                visiteur: (e as Map)['visiteur'] as String? ?? '',
                lien: e['lien'] as String?,
                heure: e['heure'] as String?,
              ))
          .toList(),
      medicamentsAdministres: (json['medicamentsAdministres'] as List? ?? [])
          .map((e) => MedicamentAdministre(
                nom: (e as Map)['nom'] as String? ?? '',
                posologiePrise: e['posologiePrise'] as String?,
                moment: e['moment'] as String? ?? '',
                pris: e['pris'] as bool? ?? false,
              ))
          .toList(),
      rapportPatient: json['rapportPatient'] as String?,
      plainte: json['plainte'] as String?,
      observations: json['observations'] as String?,
      conclusion: json['conclusion'] as String?,
      resumeIA: json['resumeIA'] as String?,
      statutRemise: json['statutRemise'] == 'en_retard' ? StatutRemiseRapport.enRetard : StatutRemiseRapport.aTemps,
      valide: json['valide'] as bool? ?? false,
    );
  }
}

class AppreciationModel {
  static Appreciation fromJson(Map<String, dynamic> json) {
    return Appreciation(
      id: (json['_id'] ?? json['id']).toString(),
      rapportId: (json['rapportId'] ?? '').toString(),
      note: (json['note'] as num?)?.toInt() ?? 0,
      commentaire: json['commentaire'] as String? ?? '',
      dateCreation: _dateOrNow(json['dateCreation']),
    );
  }
}

class DocumentMedicalModel {
  static DocumentMedicalDossier fromJson(Map<String, dynamic> json) {
    return DocumentMedicalDossier(
      id: (json['_id'] ?? json['id']).toString(),
      type: json['type'] as String? ?? 'autre',
      nomFichier: json['nomFichier'] as String?,
      url: json['url'] as String? ?? '',
      dateAjout: _dateOrNow(json['createdAt']),
    );
  }
}

class RendezVousModel {
  static RendezVousDossier fromJson(Map<String, dynamic> json) {
    final medecin = json['medecinId'];
    final medecinMap = medecin is Map ? medecin : null;
    return RendezVousDossier(
      id: (json['_id'] ?? json['id']).toString(),
      date: _dateOrNow(json['date']),
      motif: json['motif'] as String?,
      lieu: json['lieu'] as String?,
      medecinNom: medecinMap == null ? null : '${medecinMap['prenom'] ?? ''} ${medecinMap['nom'] ?? ''}'.trim(),
      statut: json['statut'] as String? ?? 'planifie',
    );
  }
}
