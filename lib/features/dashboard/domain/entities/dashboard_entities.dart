/// Entités du tableau de bord santé (UC2), alignées sur la vraie réponse de
/// `GET /api/patients/moi/dashboard` — voir
/// `data/models/dashboard_models.dart` pour le mapping JSON -> entité.

class ContactUrgence {
  final String? nom;
  final String? lien;
  final String? telephone;

  const ContactUrgence({this.nom, this.lien, this.telephone});

  bool get estVide => (nom == null || nom!.isEmpty) && (telephone == null || telephone!.isEmpty);
}

/// La fiche administrative complète du patient suivi (dossier médical).
class DossierPatient {
  final String id;
  final String? ficheNumero;
  final String nom;
  final String prenom;
  final int? age;
  final DateTime? dateNaissance;
  final String? ville;
  final String? quartier;
  final String? adresse;
  final String? pathologie;
  final List<String> antecedents;
  final List<String> allergies;
  final ContactUrgence? contactUrgence;
  final String? photoUrl;
  final String? medecinReferentNom;
  final String? medecinReferentTelephone;
  final String? medecinReferentSpecialite;

  const DossierPatient({
    required this.id,
    this.ficheNumero,
    required this.nom,
    required this.prenom,
    this.age,
    this.dateNaissance,
    this.ville,
    this.quartier,
    this.adresse,
    this.pathologie,
    this.antecedents = const [],
    this.allergies = const [],
    this.contactUrgence,
    this.photoUrl,
    this.medecinReferentNom,
    this.medecinReferentTelephone,
    this.medecinReferentSpecialite,
  });

  String get nomComplet => '$prenom $nom';
}

/// L'AVS actuellement assigné au patient (affectation active).
class AvsAssigne {
  final String id;
  final String nom;
  final String prenom;
  final String? telephone;
  final String? zoneAffectation;

  const AvsAssigne({
    required this.id,
    required this.nom,
    required this.prenom,
    this.telephone,
    this.zoneAffectation,
  });

  String get nomComplet => '$prenom $nom';
}

/// Un relevé de constantes (matin ou soir) d'un rapport journalier.
class ParametresVitaux {
  final String moment;
  final String? pouls;
  final String? taBrasDroit;
  final String? taBrasGauche;
  final String? temperature;
  final String? spo2;
  final String? glycemie;

  const ParametresVitaux({
    required this.moment,
    this.pouls,
    this.taBrasDroit,
    this.taBrasGauche,
    this.temperature,
    this.spo2,
    this.glycemie,
  });
}

/// Aperçu du dernier rapport de soins rédigé par l'AVS (déjà validé par un
/// médecin — voir la restriction côté backend dans `rapportController.js`).
class DernierRapport {
  final String id;
  final DateTime date;
  final String? avsNom;
  final String? medecinValidateurNom;
  final List<ParametresVitaux> parametresVitaux;
  final List<String> soinsTaches;
  final String? observations;
  final String? conclusion;
  final String? resumeIA;
  final bool valide;

  const DernierRapport({
    required this.id,
    required this.date,
    this.avsNom,
    this.medecinValidateurNom,
    this.parametresVitaux = const [],
    this.soinsTaches = const [],
    this.observations,
    this.conclusion,
    this.resumeIA,
    this.valide = false,
  });

  ParametresVitaux? get dernierReleve => parametresVitaux.isEmpty ? null : parametresVitaux.last;
}

/// Une ligne de traitement (ordonnance) en cours.
class TraitementActif {
  final String id;
  final String medicament;
  final String? dosage;
  final String? posologieMatin;
  final String? posologieMidi;
  final String? posologieSoir;

  const TraitementActif({
    required this.id,
    required this.medicament,
    this.dosage,
    this.posologieMatin,
    this.posologieMidi,
    this.posologieSoir,
  });
}

class ProchainRendezVous {
  final String id;
  final DateTime date;
  final String? motif;
  final String? lieu;
  final String? medecinNom;
  final String? medecinSpecialite;

  const ProchainRendezVous({
    required this.id,
    required this.date,
    this.motif,
    this.lieu,
    this.medecinNom,
    this.medecinSpecialite,
  });
}

enum StatutAlerte { ouverte, enCours, resolue }

StatutAlerte statutAlerteFromString(String? value) {
  switch (value) {
    case 'en_cours':
      return StatutAlerte.enCours;
    case 'resolue':
      return StatutAlerte.resolue;
    case 'ouverte':
    default:
      return StatutAlerte.ouverte;
  }
}

class AlerteOuverte {
  final String id;
  final String type;
  final String? description;
  final StatutAlerte statut;
  final DateTime dateCreation;

  const AlerteOuverte({
    required this.id,
    required this.type,
    this.description,
    required this.statut,
    required this.dateCreation,
  });
}

class DocumentRecent {
  final String id;
  final String type;
  final String? nomFichier;
  final String url;
  final DateTime dateAjout;

  const DocumentRecent({
    required this.id,
    required this.type,
    this.nomFichier,
    required this.url,
    required this.dateAjout,
  });
}

/// L'agrégat complet renvoyé par `GET /api/patients/moi/dashboard`, tel que
/// consommé par la page d'accueil (UC2).
class TableauDeBord {
  final DossierPatient patient;
  final AvsAssigne? avsAssigne;
  final DernierRapport? dernierRapport;
  final List<TraitementActif> traitementsActifs;
  final ProchainRendezVous? prochainRendezVous;
  final List<AlerteOuverte> alertesOuvertes;
  final List<DocumentRecent> documentsRecents;
  final int notificationsNonLues;

  const TableauDeBord({
    required this.patient,
    this.avsAssigne,
    this.dernierRapport,
    this.traitementsActifs = const [],
    this.prochainRendezVous,
    this.alertesOuvertes = const [],
    this.documentsRecents = const [],
    this.notificationsNonLues = 0,
  });
}
