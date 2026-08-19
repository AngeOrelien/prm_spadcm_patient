/// Onglet 3 — Dossier (section 7.1 README) : antécédents, traitements,
/// rapports journaliers, documents médicaux, calendrier RDV, évolution IA,
/// notation de l'AVS.

class ContactUrgenceDossier {
  final String? nom;
  final String? lien;
  final String? telephone;

  const ContactUrgenceDossier({this.nom, this.lien, this.telephone});
}

class ResumePatient {
  final String nom;
  final String prenom;
  final String? ficheNumero;
  final DateTime? dateNaissance;
  final String? ville;
  final String? quartier;
  final List<String> antecedents;
  final List<String> allergies;
  final List<String> difficultesMobilite;
  final ContactUrgenceDossier? contactUrgence;

  /// Nom complet de l'AVS assigné au patient (déduit de `avsAssigne`, à côté
  /// de `patient` dans la réponse de `GET /patients/moi`). `null` tant
  /// qu'aucun·e AVS n'a été assigné·e par un coordonnateur.
  final String? avsNom;

  const ResumePatient({
    required this.nom,
    required this.prenom,
    this.ficheNumero,
    this.dateNaissance,
    this.ville,
    this.quartier,
    this.antecedents = const [],
    this.allergies = const [],
    this.difficultesMobilite = const [],
    this.contactUrgence,
    this.avsNom,
  });

  String get nomComplet => '$prenom $nom';

  int? get age {
    if (dateNaissance == null) return null;
    final maintenant = DateTime.now();
    var age = maintenant.year - dateNaissance!.year;
    if (maintenant.month < dateNaissance!.month ||
        (maintenant.month == dateNaissance!.month && maintenant.day < dateNaissance!.day)) {
      age--;
    }
    return age;
  }
}

class Traitement {
  final String id;
  final String medicament;
  final String? dosage;
  final String? posologieMatin;
  final String? posologieMidi;
  final String? posologieSoir;
  final String statut;

  const Traitement({
    required this.id,
    required this.medicament,
    this.dosage,
    this.posologieMatin,
    this.posologieMidi,
    this.posologieSoir,
    this.statut = 'actif',
  });
}

class ParametresVitauxDossier {
  final String moment;
  final String? pouls;
  final String? taBrasDroit;
  final String? taBrasGauche;
  final String? temperature;
  final String? spo2;
  final String? glycemie;

  const ParametresVitauxDossier({
    required this.moment,
    this.pouls,
    this.taBrasDroit,
    this.taBrasGauche,
    this.temperature,
    this.spo2,
    this.glycemie,
  });
}

class VisiteRecue {
  final String visiteur;
  final String? lien;
  final String? heure;

  const VisiteRecue({required this.visiteur, this.lien, this.heure});
}

class MedicamentAdministre {
  final String nom;
  final String? posologiePrise;
  final String moment;
  final bool pris;

  const MedicamentAdministre({required this.nom, this.posologiePrise, required this.moment, required this.pris});
}

enum StatutRemiseRapport { aTemps, enRetard }

class RapportJournalier {
  final String id;
  final DateTime date;
  final String? avsNom;
  final List<ParametresVitauxDossier> parametresVitaux;
  final List<String> soinsTaches;
  final List<String> activites;
  final List<VisiteRecue> visites;
  final List<MedicamentAdministre> medicamentsAdministres;
  final String? rapportPatient;
  final String? plainte;
  final String? observations;
  final String? conclusion;
  final String? resumeIA;
  final StatutRemiseRapport statutRemise;
  final bool valide;

  const RapportJournalier({
    required this.id,
    required this.date,
    this.avsNom,
    this.parametresVitaux = const [],
    this.soinsTaches = const [],
    this.activites = const [],
    this.visites = const [],
    this.medicamentsAdministres = const [],
    this.rapportPatient,
    this.plainte,
    this.observations,
    this.conclusion,
    this.resumeIA,
    this.statutRemise = StatutRemiseRapport.aTemps,
    this.valide = false,
  });
}

class Appreciation {
  final String id;
  final String rapportId;
  final int note;
  final String commentaire;
  final DateTime dateCreation;

  const Appreciation({
    required this.id,
    required this.rapportId,
    required this.note,
    required this.commentaire,
    required this.dateCreation,
  });
}

class DocumentMedicalDossier {
  final String id;
  final String type;
  final String? nomFichier;
  final String url;
  final DateTime dateAjout;

  const DocumentMedicalDossier({
    required this.id,
    required this.type,
    this.nomFichier,
    required this.url,
    required this.dateAjout,
  });
}

class RendezVousDossier {
  final String id;
  final DateTime date;
  final String? motif;
  final String? lieu;
  final String? medecinNom;
  final String statut;

  const RendezVousDossier({
    required this.id,
    required this.date,
    this.motif,
    this.lieu,
    this.medecinNom,
    this.statut = 'planifie',
  });

  bool get estAVenir => date.isAfter(DateTime.now());
}
