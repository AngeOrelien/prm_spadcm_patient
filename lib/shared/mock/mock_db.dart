/// "Base de données" en mémoire pour le mode mock (voir [AppConfig]).
///
/// Chaque collection est une liste de `Map<String, dynamic>` qui reprend
/// volontairement la forme des documents MongoDB décrits dans le README
/// (section 6.3) : mêmes noms de champs, mêmes relations par `...Id`. Ça
/// permet à chaque datasource de parser ce mock exactement comme elle
/// parsera plus tard une vraie réponse JSON du backend.
///
/// Les listes ne sont pas `const`/`final` : les pages "Messages", "SOS" et
/// "Noter l'AVS" y ajoutent des entrées en mémoire pendant la session (pas
/// de persistance disque, l'app repart de ce jeu de données à chaque
/// redémarrage).
class MockDb {
  MockDb._();

  static int _seq = 1000;
  static String nextId(String prefix) => '${prefix}_${_seq++}';

  // --- Compte connecté (membre de famille) + patient suivi ---
  //
  // Le README (section 3.1, point 8) prévoit qu'un proche pilote souvent
  // l'app à la place de la personne âgée : le compte connecté par défaut
  // est donc "famille", lié au dossier du patient.

  static final utilisateurConnecte = {
    'id': 'user_1',
    'nom': 'Etoundi',
    'prenom': 'Paul',
    'email': 'paul.etoundi@gmail.com',
    'telephone': '+237 677 12 34 56',
    'role': 'famille',
    'biometrieActive': false,
  };

  static final medecinReferent = {
    '_id': 'med_1',
    'nom': 'Ateba',
    'prenom': 'Samuel',
    'specialite': 'Gériatrie',
    'telephone': '+237 699 45 67 89',
  };

  static final avsAssigne = {
    '_id': 'avs_1',
    'nom': 'Mballa',
    'prenom': 'Adèle',
    'telephone': '+237 690 11 22 33',
    'zoneAffectation': 'Bastos, Yaoundé',
    'grade': 'AVS Senior',
  };

  static final coordonnateur = {
    '_id': 'coord_1',
    'nom': 'Fouda',
    'prenom': 'Bernard',
    'role': 'coordonnateur',
  };

  static final patient = {
    '_id': 'pat_1',
    'ficheNumero': 'SPAD-2024-0187',
    'nom': 'Etoundi',
    'prenom': 'Marguerite',
    'dateNaissance': '1948-03-12T00:00:00.000Z',
    'ville': 'Yaoundé',
    'quartier': 'Bastos',
    'adresse': 'Rue 1.812, derrière la pharmacie Bastos',
    'pathologie': 'Hypertension artérielle, diabète de type 2',
    'antecedents': ['Hypertension artérielle', 'Diabète de type 2', 'Arthrose du genou droit'],
    'allergies': ['Pénicilline'],
    'difficultesMobilite': ['Marche avec déambulateur', 'Risque de chute'],
    'contactUrgence': {
      'nom': 'Paul Etoundi',
      'lien': 'Fils',
      'telephone': '+237 677 12 34 56',
    },
    'medecinReferentId': medecinReferent,
    'compteUtilisateurId': utilisateurConnecte['id'],
  };

  /// Membres de famille liés au dossier (UC12 "Compte famille").
  /// Le premier est le compte actuellement connecté.
  static final membresFamille = [
    {
      'id': 'user_1',
      'nom': 'Etoundi',
      'prenom': 'Paul',
      'lien': 'Fils',
      'email': 'paul.etoundi@gmail.com',
      'telephone': '+237 677 12 34 56',
      'estCompteConnecte': true,
    },
    {
      'id': 'user_2',
      'nom': 'Etoundi',
      'prenom': 'Chantal',
      'lien': 'Fille',
      'email': 'chantal.etoundi@gmail.com',
      'telephone': '+237 655 98 76 54',
      'estCompteConnecte': false,
    },
  ];

  // --- Catalogue de soins / souscription / paiement ---

  static final soinsCatalogue = [
    {
      '_id': 'soin_1',
      'nom': 'Accompagnement Essentiel',
      'description':
          'Suivi de base à domicile : constantes vitales, aide à la toilette et '
          'rappel des prises de médicaments.',
      'prix': 45000,
      'frequenceVisites': '3 visites / semaine',
      'prestationsIncluses': [
        'Prise des constantes (matin/soir)',
        'Aide à la toilette et à l\'habillage',
        'Rappel et suivi des prises médicamenteuses',
      ],
    },
    {
      '_id': 'soin_2',
      'nom': 'Accompagnement Confort',
      'description':
          'Le forfait le plus souscrit : accompagnement quotidien renforcé avec '
          'aide aux repas et activités de stimulation.',
      'prix': 75000,
      'frequenceVisites': '5 visites / semaine',
      'prestationsIncluses': [
        'Prise des constantes (matin/soir)',
        'Aide à la toilette et à l\'habillage',
        'Accompagnement aux repas',
        'Activités de stimulation (mémoire, mobilité douce)',
        'Compte-rendu quotidien à la famille',
      ],
    },
    {
      '_id': 'soin_3',
      'nom': 'Accompagnement Premium 24/7',
      'description':
          'Présence continue au domicile pour les besoins les plus importants, '
          'avec coordination directe avec le médecin référent.',
      'prix': 150000,
      'frequenceVisites': 'Présence quotidienne continue',
      'prestationsIncluses': [
        'Présence continue (jour et nuit)',
        'Gestion complète des soins et médicaments',
        'Coordination avec le médecin référent',
        'Rapport détaillé et alerte prioritaire',
      ],
    },
  ];

  static final List<Map<String, dynamic>> paiements = [
    {
      '_id': 'pai_1',
      'montant': 75000,
      'devise': 'XAF',
      'statut': 'reussi',
      'referenceExterne': 'MOMO-88213764',
      'dateTransaction': DateTime.now().subtract(const Duration(days: 62)).toIso8601String(),
    },
    {
      '_id': 'pai_2',
      'montant': 75000,
      'devise': 'XAF',
      'statut': 'reussi',
      'referenceExterne': 'MOMO-88459021',
      'dateTransaction': DateTime.now().subtract(const Duration(days: 32)).toIso8601String(),
    },
    {
      '_id': 'pai_3',
      'montant': 75000,
      'devise': 'XAF',
      'statut': 'reussi',
      'referenceExterne': 'MOMO-88790456',
      'dateTransaction': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
    },
  ];

  static final souscriptions = [
    {
      '_id': 'sou_1',
      'soinId': soinsCatalogue[1],
      'paiementId': paiements[2]['_id'],
      'dateDebut': DateTime.now().subtract(const Duration(days: 62)).toIso8601String(),
      'dateFin': DateTime.now().add(const Duration(days: 28)).toIso8601String(),
      'statut': 'active',
    },
  ];

  // --- Traitement de fond (ordonnance) ---

  static final traitements = [
    {
      '_id': 'trt_1',
      'medicament': 'Amlodipine',
      'dosage': '5 mg',
      'posologieMatin': '1',
      'posologieMidi': '',
      'posologieSoir': '',
      'dateDebut': DateTime.now().subtract(const Duration(days: 180)).toIso8601String(),
      'statut': 'actif',
    },
    {
      '_id': 'trt_2',
      'medicament': 'Metformine',
      'dosage': '850 mg',
      'posologieMatin': '1',
      'posologieMidi': '0',
      'posologieSoir': '1',
      'dateDebut': DateTime.now().subtract(const Duration(days: 180)).toIso8601String(),
      'statut': 'actif',
    },
    {
      '_id': 'trt_3',
      'medicament': 'Paracétamol',
      'dosage': '500 mg',
      'posologieMatin': 'Si douleur',
      'posologieMidi': '',
      'posologieSoir': 'Si douleur',
      'dateDebut': DateTime.now().subtract(const Duration(days: 40)).toIso8601String(),
      'statut': 'actif',
    },
  ];

  // --- Rapports journaliers (fiche terrain de l'AVS) ---

  static List<Map<String, dynamic>> rapportsJournaliers = List.generate(6, (i) {
    final date = DateTime.now().subtract(Duration(days: i * 2));
    final enRetard = i == 2;
    return {
      '_id': 'rap_${6 - i}',
      'patientId': patient['_id'],
      'avsId': avsAssigne,
      'coordinateurValidateurId': i == 0 ? null : coordonnateur,
      'date': date.toIso8601String(),
      'heureSaisie': date.add(const Duration(hours: 17, minutes: 40)).toIso8601String(),
      'heureSynchronisation': date.add(const Duration(hours: 18, minutes: 5)).toIso8601String(),
      'parametresVitaux': [
        {
          'moment': 'matin',
          'pouls': '${74 + i}',
          'taBrasDroit': '13/8',
          'taBrasGauche': '13/8',
          'temperature': '36.${6 + (i % 3)}',
          'frequenceRespiratoire': '18',
          'glycemie': '${105 + i * 2} mg/dL',
          'spo2': '${96 + (i % 3)}%',
          'glasgow': 15,
        },
        {
          'moment': 'soir',
          'pouls': '${78 + i}',
          'taBrasDroit': '14/9',
          'taBrasGauche': '14/8',
          'temperature': '36.${7 + (i % 2)}',
          'frequenceRespiratoire': '19',
          'glycemie': '${112 + i * 2} mg/dL',
          'spo2': '${96 + (i % 2)}%',
          'glasgow': 15,
        },
      ],
      'evaluationBesoins': {
        'respirer': 'Autonome',
        'dormir': 'Sommeil agité, 2 réveils nocturnes',
        'boireEtManger': 'Aide partielle nécessaire',
        'seMouvoir': 'Déambulateur, aide à la marche',
        'hygieneCorporelle': 'Aide complète à la toilette',
        'portProthese': 'Prothèse auditive droite',
      },
      'alimentation': {
        'petitDejeuner': 'Bouillie de mil, thé',
        'dejeuner': 'Riz, poisson, légumes',
        'diner': 'Soupe de légumes, pain',
        'hydratation': '1.2 L',
        'fruits': 'Banane, orange',
      },
      'medicamentsAdministres': [
        {'nom': 'Amlodipine', 'posologiePrise': '1 cp', 'moment': 'matin', 'pris': true, 'traitementId': 'trt_1'},
        {'nom': 'Metformine', 'posologiePrise': '1 cp', 'moment': 'matin', 'pris': true, 'traitementId': 'trt_2'},
        {'nom': 'Metformine', 'posologiePrise': '1 cp', 'moment': 'soir', 'pris': i != 4, 'traitementId': 'trt_2'},
      ],
      'soinsTaches': ['Prise des constantes', 'Aide à la toilette', 'Aide à l\'habillage', 'Rappel médicaments'],
      'activites': i.isEven ? ['Marche assistée (15 min)', 'Jeu de mémoire'] : ['Discussion, lecture du journal'],
      'visites': i == 1
          ? [
              {'visiteur': 'Chantal Etoundi', 'lien': 'Fille', 'heure': '16h30'},
            ]
          : [],
      'rapportPatient': 'Bon appétit, transit normal, a bien dormi la sieste.',
      'plainte': i == 2 ? 'Légère douleur au genou droit en fin de journée.' : '',
      'observations': i == 2
          ? 'Douleur articulaire signalée, à surveiller. Reste autonome pour les gestes simples.'
          : 'Journée calme, patiente de bonne humeur, aucune anomalie constatée.',
      'conclusion': 'Visite terminée sans incident, prochaine visite selon planning habituel.',
      'statutRemise': enRetard ? 'en_retard' : 'a_temps',
      'valide': i != 0,
      'resumeIA': i == 2
          ? "Résumé IA : légère douleur articulaire rapportée, constantes stables par ailleurs. "
              "Aucune anomalie critique détectée."
          : "Résumé IA : constantes stables, bonne autonomie, journée sans incident notable.",
    };
  });

  // --- Appréciations (notation de l'AVS par la famille) ---

  static List<Map<String, dynamic>> appreciations = [
    {
      '_id': 'app_1',
      'rapportId': 'rap_5',
      'avsId': avsAssigne['_id'],
      'note': 5,
      'commentaire': 'Adèle est toujours très douce et patiente avec maman, merci !',
      'dateCreation': DateTime.now().subtract(const Duration(days: 9)).toIso8601String(),
    },
    {
      '_id': 'app_2',
      'rapportId': 'rap_3',
      'avsId': avsAssigne['_id'],
      'note': 4,
      'commentaire': 'Bonne visite, juste un peu en retard ce jour-là.',
      'dateCreation': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
    },
  ];

  // --- Documents médicaux ---

  static final documentsMedicaux = [
    {
      '_id': 'doc_1',
      'type': 'ordonnance',
      'nomFichier': 'Ordonnance_Dr_Ateba_Juin.pdf',
      'url': 'https://example.org/documents/ordonnance-juin.pdf',
      'createdAt': DateTime.now().subtract(const Duration(days: 20)).toIso8601String(),
    },
    {
      '_id': 'doc_2',
      'type': 'analyse',
      'nomFichier': 'Bilan_glycemie_labo_central.pdf',
      'url': 'https://example.org/documents/bilan-glycemie.pdf',
      'createdAt': DateTime.now().subtract(const Duration(days: 15)).toIso8601String(),
    },
    {
      '_id': 'doc_3',
      'type': 'compte_rendu',
      'nomFichier': 'Compte_rendu_consultation_cardio.pdf',
      'url': 'https://example.org/documents/cr-cardio.pdf',
      'createdAt': DateTime.now().subtract(const Duration(days: 4)).toIso8601String(),
    },
  ];

  // --- Rendez-vous ---

  static List<Map<String, dynamic>> rendezVous = [
    {
      '_id': 'rdv_1',
      'medecinId': medecinReferent,
      'date': DateTime.now().add(const Duration(days: 6, hours: 3)).toIso8601String(),
      'motif': 'Consultation de suivi trimestrielle',
      'lieu': 'Cabinet Dr Ateba, Bastos',
      'statut': 'planifie',
    },
    {
      '_id': 'rdv_2',
      'medecinId': medecinReferent,
      'date': DateTime.now().subtract(const Duration(days: 25)).toIso8601String(),
      'motif': 'Bilan cardiologique',
      'lieu': 'Hôpital Central, Yaoundé',
      'statut': 'termine',
    },
  ];

  // --- Alertes (SOS) ---

  static List<Map<String, dynamic>> alertes = [];

  // --- Messagerie : deux fils, Administration et AVS assigné ---

  static List<Map<String, dynamic>> conversations = [
    {
      '_id': 'conv_admin',
      'type': 'administration',
      'titre': 'Administration SPAD',
      'interlocuteur': coordonnateur,
    },
    {
      '_id': 'conv_avs',
      'type': 'avs',
      'titre': 'Adèle M. (AVS)',
      'interlocuteur': avsAssigne,
    },
  ];

  static List<Map<String, dynamic>> messages = [
    {
      '_id': 'msg_1',
      'conversationId': 'conv_admin',
      'expediteurId': coordonnateur['_id'],
      'contenu': 'Bonjour, votre souscription "Accompagnement Confort" a bien été renouvelée ce mois-ci.',
      'lu': true,
      'dateEnvoi': DateTime.now().subtract(const Duration(days: 6, hours: 2)).toIso8601String(),
    },
    {
      '_id': 'msg_2',
      'conversationId': 'conv_admin',
      'expediteurId': 'user_1',
      'contenu': 'Merci beaucoup, tout s\'est bien passé pour le paiement.',
      'lu': true,
      'dateEnvoi': DateTime.now().subtract(const Duration(days: 6, hours: 1)).toIso8601String(),
    },
    {
      '_id': 'msg_3',
      'conversationId': 'conv_admin',
      'expediteurId': coordonnateur['_id'],
      'contenu': 'Un nouveau tensiomètre a été remis à Adèle pour les prochaines visites.',
      'lu': false,
      'dateEnvoi': DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
    },
    {
      '_id': 'msg_4',
      'conversationId': 'conv_avs',
      'expediteurId': 'avs_1',
      'contenu': 'Bonjour, je passerai un peu plus tôt demain, vers 8h15, si cela convient.',
      'lu': true,
      'dateEnvoi': DateTime.now().subtract(const Duration(days: 1, hours: 4)).toIso8601String(),
    },
    {
      '_id': 'msg_5',
      'conversationId': 'conv_avs',
      'expediteurId': 'user_1',
      'contenu': 'Oui pas de souci, on vous attend.',
      'lu': true,
      'dateEnvoi': DateTime.now().subtract(const Duration(days: 1, hours: 3)).toIso8601String(),
    },
    {
      '_id': 'msg_6',
      'conversationId': 'conv_avs',
      'expediteurId': 'avs_1',
      'contenu': 'Visite terminée, maman a bien mangé ce midi et est en train de se reposer.',
      'lu': false,
      'dateEnvoi': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
    },
  ];

  static int get notificationsNonLues =>
      messages.where((m) => m['lu'] == false).length + alertes.where((a) => a['statut'] != 'resolue').length;
}
