import '../../features/dashboard/domain/entities/dashboard_entities.dart';
import '../../features/dossier/domain/entities/dossier_entities.dart';
import '../../features/messagerie/domain/entities/messagerie_entities.dart';
import '../../features/profil/domain/entities/membre_famille.dart';
import '../../features/soins/domain/entities/soins_entities.dart';
import '../config/app_config.dart';

/// **Mock backend** unique de l'app SPAD Cameroun (Patients/Familles).
///
/// Tant que `prm-spad-backend` n'a pas encore les routes de la V2
/// (catalogue de soins, souscriptions, paiements, présences, appréciations
/// — voir README section 6), toutes les couches `data` de l'app passent par
/// cette classe plutôt que par un vrai appel réseau : mêmes signatures
/// async, même latence simulée, mêmes formes de données que ce que
/// renverra l'API plus tard. Basculer vers le vrai backend consistera
/// uniquement à remplacer, feature par feature, l'appel à [MockBackend] par
/// un appel à un `XxxRemoteDataSource` (Dio) équivalent — voir
/// `AppConfig.useMockData`.
///
/// Toutes les données ci-dessous sont statiques/fictives (patient et
/// personnel imaginaires basés a Yaounde), et certaines listes (alertes,
/// messages, paiements, appreciations) sont mutables en memoire pour que
/// les actions de l'utilisateur (envoyer un message, souscrire a un soin,
/// declencher une alerte, noter l'AVS) se refletent immediatement dans
/// l'app pendant la session, sans persister au redemarrage.
class MockBackend {
  MockBackend._internal();

  static final MockBackend instance = MockBackend._internal();

  Future<void> _latence() => Future.delayed(AppConfig.mockLatency);

  final DateTime _maintenant = DateTime.now();

  late final DossierPatient _patient = DossierPatient(
    id: 'patient-001',
    ficheNumero: 'SPAD-2026-0142',
    nom: 'Mballa',
    prenom: 'Jeanne',
    age: 78,
    dateNaissance: DateTime(1948, 3, 14),
    ville: 'Yaounde',
    quartier: 'Bastos',
    adresse: 'Rue 1.234, Bastos',
    pathologie: 'Maladie de Parkinson, hypertension arterielle',
    antecedents: const [
      'Hypertension arterielle (2015)',
      'Diabete de type 2 (2019)',
      'Maladie de Parkinson (2021)',
    ],
    allergies: const ['Penicilline'],
    difficultesMobilite: const ['Marche assistee (deambulateur)', 'Difficulte a monter les escaliers'],
    contactUrgence: const ContactUrgence(
      nom: 'Paul Mballa',
      lien: 'Fils',
      telephone: '+237 6 77 12 34 56',
    ),
    medecinReferentNom: 'Ateba Ngono',
    medecinReferentTelephone: '+237 6 55 44 33 22',
    medecinReferentSpecialite: 'Geriatrie (role encore a l\'etude)',
  );

  late final AvsAssigne _avs = const AvsAssigne(
    id: 'avs-014',
    nom: 'Ndongo',
    prenom: 'Mariam',
    telephone: '+237 6 90 11 22 33',
    zoneAffectation: 'Bastos / Nlongkak',
  );

  late final List<TraitementDetail> _traitements = [
    const TraitementDetail(
      id: 'trt-1',
      medicament: 'Modopar 250',
      dosage: '200mg/50mg',
      posologieMatin: '1',
      posologieMidi: '0',
      posologieSoir: '1',
      statut: 'actif',
    ),
    const TraitementDetail(
      id: 'trt-2',
      medicament: 'Amlodipine',
      dosage: '5mg',
      posologieMatin: '1',
      posologieMidi: '0',
      posologieSoir: '0',
      statut: 'actif',
    ),
    const TraitementDetail(
      id: 'trt-3',
      medicament: 'Metformine',
      dosage: '850mg',
      posologieMatin: '1',
      posologieMidi: '1',
      posologieSoir: '0',
      statut: 'actif',
    ),
  ];

  late final List<RapportJournalier> _rapports = List.generate(6, (i) {
    final date = _maintenant.subtract(Duration(days: i));
    final enRetard = i == 2;
    return RapportJournalier(
      id: 'rapport-$i',
      date: date,
      avsNom: _avs.nomComplet,
      validateurNom: i == 0 ? null : 'Coordonnateur Fotso',
      valide: i != 0,
      statutRemise: enRetard ? 'en_retard' : 'a_temps',
      parametresVitaux: [
        ReleveVital(
          moment: 'matin',
          pouls: '${76 + i}',
          tension: '13${i % 3}/8${i % 2}',
          temperature: '36.${5 + (i % 3)}',
          spo2: '9${6 + (i % 3)}',
          glycemie: '1.${10 + i}',
        ),
        ReleveVital(
          moment: 'soir',
          pouls: '${80 + i}',
          tension: '13${(i + 1) % 3}/8${(i + 1) % 2}',
          temperature: '36.${6 + (i % 2)}',
          spo2: '9${7 + (i % 2)}',
          glycemie: '1.${15 + i}',
        ),
      ],
      soinsTaches: const ['Bain assiste', 'Hygiene bucco-dentaire', 'Aide a l\'habillage'],
      activites: i.isEven ? const ['Petite marche au jardin', 'Seance de kinesitherapie'] : const ['Jeux de memoire'],
      rapportPatient: 'Bon appetit, selles normales, urines claires.',
      observations: i == 2
          ? 'Legere agitation en fin de journee, a mieux dormi apres la prise du soir.'
          : 'Journee calme, patiente souriante et cooperative.',
      conclusion: 'Aucune anomalie majeure relevee, a poursuivre.',
      resumeIA: i.isEven
          ? "Constantes stables, patiente en bonne forme generale. Aucun signal d'alerte detecte par l'analyse automatique."
          : null,
    );
  });

  late final List<DocumentMedical> _documents = [
    DocumentMedical(
      id: 'doc-1',
      type: 'ordonnance',
      nomFichier: 'Ordonnance_Dr_Ateba_Juin2026.pdf',
      dateAjout: _maintenant.subtract(const Duration(days: 20)),
    ),
    DocumentMedical(
      id: 'doc-2',
      type: 'analyse',
      nomFichier: 'Bilan_glycemie_Mai2026.pdf',
      dateAjout: _maintenant.subtract(const Duration(days: 45)),
    ),
    DocumentMedical(
      id: 'doc-3',
      type: 'compte_rendu',
      nomFichier: 'Compte_rendu_consultation_Avril2026.pdf',
      dateAjout: _maintenant.subtract(const Duration(days: 80)),
    ),
  ];

  late final List<RendezVousItem> _rendezVous = [
    RendezVousItem(
      id: 'rdv-1',
      date: _maintenant.add(const Duration(days: 5, hours: 3)),
      motif: 'Consultation de suivi tensionnel',
      lieu: 'Hopital Central de Yaounde',
      medecinNom: 'Dr Ateba Ngono',
      statut: 'planifie',
    ),
    RendezVousItem(
      id: 'rdv-2',
      date: _maintenant.subtract(const Duration(days: 30)),
      motif: 'Bilan trimestriel',
      lieu: 'Hopital Central de Yaounde',
      medecinNom: 'Dr Ateba Ngono',
      statut: 'termine',
    ),
  ];

  late final List<PointEvolutionSante> _evolutionSante = List.generate(8, (i) {
    final date = _maintenant.subtract(Duration(days: (7 - i) * 7));
    final base = 62.0 + i * 3.5;
    return PointEvolutionSante(date: date, score: base.clamp(0, 100));
  });

  final List<AppreciationAvs> _appreciations = [
    AppreciationAvs(
      id: 'appr-1',
      note: 5,
      commentaire: 'Toujours ponctuelle et tres douce avec maman.',
      date: DateTime.now().subtract(const Duration(days: 6)),
    ),
    AppreciationAvs(
      id: 'appr-2',
      note: 4,
      commentaire: 'Bon suivi, un petit retard exceptionnel cette semaine.',
      date: DateTime.now().subtract(const Duration(days: 13)),
    ),
  ];

  late final List<SoinCatalogueItem> _catalogue = [
    const SoinCatalogueItem(
      id: 'soin-1',
      nom: 'Suivi sante & nutrition quotidien',
      description:
          "Visite quotidienne d'un AVS : prise de constantes, aide a la toilette, "
          'suivi nutritionnel et administration des medicaments.',
      prix: 85000,
      frequenceVisites: 'Quotidienne',
      prestationsIncluses: ['Sante', 'Nutrition', 'Hygiene', 'Medication'],
    ),
    const SoinCatalogueItem(
      id: 'soin-2',
      nom: 'Accompagnement 3x/semaine',
      description:
          'Visites trois fois par semaine : constantes vitales, hygiene de base '
          'et compagnie pour les activites quotidiennes.',
      prix: 45000,
      frequenceVisites: '3x / semaine',
      prestationsIncluses: ['Sante', 'Hygiene', 'Compagnie'],
    ),
    const SoinCatalogueItem(
      id: 'soin-3',
      nom: 'Soins palliatifs renforces',
      description:
          'Deux visites par jour avec un AVS qualifie, suivi medical rapproche '
          'et coordination renforcee avec le medecin referent.',
      prix: 150000,
      frequenceVisites: '2x / jour',
      prestationsIncluses: ['Sante', 'Nutrition', 'Hygiene', 'Medication', 'Suivi medical rapproche'],
    ),
  ];

  SouscriptionActive? _souscriptionActive = SouscriptionActive(
    id: 'sousc-1',
    soinId: 'soin-1',
    soinNom: 'Suivi sante & nutrition quotidien',
    dateDebut: DateTime.now().subtract(const Duration(days: 40)),
    dateFin: DateTime.now().add(const Duration(days: 20)),
    statut: 'active',
  );

  final List<PaiementItem> _paiements = [
    PaiementItem(
      id: 'pay-1',
      montant: 85000,
      statut: 'reussi',
      moyenPaiement: 'Mobile Money (MTN)',
      dateTransaction: DateTime.now().subtract(const Duration(days: 40)),
      soinNom: 'Suivi sante & nutrition quotidien',
    ),
    PaiementItem(
      id: 'pay-2',
      montant: 85000,
      statut: 'reussi',
      moyenPaiement: 'Orange Money',
      dateTransaction: DateTime.now().subtract(const Duration(days: 10)),
      soinNom: 'Suivi sante & nutrition quotidien',
    ),
  ];

  final List<MembreFamille> _membresFamille = [
    const MembreFamille(
      id: 'user-famille-1',
      nom: 'Mballa',
      prenom: 'Paul',
      lien: 'Fils',
      email: 'paul.mballa@example.com',
      estCompteActuel: true,
    ),
    const MembreFamille(
      id: 'user-famille-2',
      nom: 'Mballa',
      prenom: 'Sandrine',
      lien: 'Fille',
      email: 'sandrine.mballa@example.com',
    ),
  ];

  final List<AlerteOuverte> _alertes = [];

  late final Map<String, List<MessageItem>> _messagesParConversation = {
    'conv-admin': [
      MessageItem(
        id: 'msg-a1',
        conversationId: 'conv-admin',
        contenu: "Bonjour, l'AVS Mariam est bien affectee a votre maman depuis lundi.",
        dateEnvoi: DateTime.now().subtract(const Duration(days: 3, hours: 2)),
        envoyeParMoi: false,
      ),
      MessageItem(
        id: 'msg-a2',
        conversationId: 'conv-admin',
        contenu: 'Merci beaucoup, tout se passe bien de notre cote.',
        dateEnvoi: DateTime.now().subtract(const Duration(days: 3, hours: 1)),
        envoyeParMoi: true,
      ),
    ],
    'conv-avs': [
      MessageItem(
        id: 'msg-v1',
        conversationId: 'conv-avs',
        contenu: 'Bonjour Madame, je serai chez vous a 9h demain matin.',
        dateEnvoi: DateTime.now().subtract(const Duration(hours: 20)),
        envoyeParMoi: false,
      ),
      MessageItem(
        id: 'msg-v2',
        conversationId: 'conv-avs',
        contenu: "Tres bien, merci Mariam. N'oubliez pas les nouveaux comprimes svp.",
        dateEnvoi: DateTime.now().subtract(const Duration(hours: 19)),
        envoyeParMoi: true,
      ),
      MessageItem(
        id: 'msg-v3',
        conversationId: 'conv-avs',
        contenu: "C'est note, a demain !",
        dateEnvoi: DateTime.now().subtract(const Duration(hours: 18, minutes: 30)),
        envoyeParMoi: false,
      ),
    ],
  };

  // ======================================================================
  // API "mock" exposee aux datasources (memes signatures que le futur vrai
  // backend, cf. commentaire de classe).
  // ======================================================================

  Future<TableauDeBord> obtenirTableauDeBord() async {
    await _latence();
    final dernierRapportBrut = _rapports.first;
    final prochains = _rendezVous.where((r) => !r.estPasse).toList();

    return TableauDeBord(
      patient: _patient,
      avsAssigne: _avs,
      dernierRapport: DernierRapport(
        id: dernierRapportBrut.id,
        date: dernierRapportBrut.date,
        avsNom: dernierRapportBrut.avsNom,
        parametresVitaux: dernierRapportBrut.parametresVitaux
            .map((r) => ParametresVitaux(
                  moment: r.moment,
                  pouls: r.pouls,
                  taBrasDroit: r.tension,
                  temperature: r.temperature,
                  spo2: r.spo2,
                  glycemie: r.glycemie,
                ))
            .toList(),
        soinsTaches: dernierRapportBrut.soinsTaches,
        observations: dernierRapportBrut.observations,
        conclusion: dernierRapportBrut.conclusion,
        resumeIA: dernierRapportBrut.resumeIA,
        valide: dernierRapportBrut.valide,
      ),
      traitementsActifs: _traitements
          .where((t) => t.statut == 'actif')
          .map((t) => TraitementActif(
                id: t.id,
                medicament: t.medicament,
                dosage: t.dosage,
                posologieMatin: t.posologieMatin,
                posologieMidi: t.posologieMidi,
                posologieSoir: t.posologieSoir,
              ))
          .toList(),
      prochainRendezVous: prochains.isEmpty
          ? null
          : ProchainRendezVous(
              id: prochains.first.id,
              date: prochains.first.date,
              motif: prochains.first.motif,
              lieu: prochains.first.lieu,
              medecinNom: prochains.first.medecinNom,
            ),
      alertesOuvertes: List.unmodifiable(_alertes),
      documentsRecents: _documents
          .map((d) => DocumentRecent(
                id: d.id,
                type: d.type,
                nomFichier: d.nomFichier,
                url: 'https://mock.spad-cameroun.cm/documents/${d.id}',
                dateAjout: d.dateAjout,
              ))
          .toList(),
      notificationsNonLues: _messagesParConversation.values
          .expand((m) => m)
          .where((m) => !m.lu && !m.envoyeParMoi)
          .length,
    );
  }

  Future<DossierComplet> obtenirDossierComplet() async {
    await _latence();
    return DossierComplet(
      antecedents: _patient.antecedents,
      allergies: _patient.allergies,
      difficultesMobilite: _patient.difficultesMobilite,
      avsNom: _avs.nomComplet,
      traitements: List.unmodifiable(_traitements),
      rapports: List.unmodifiable(_rapports),
      documents: List.unmodifiable(_documents),
      rendezVous: List.unmodifiable(_rendezVous),
      evolutionSante: List.unmodifiable(_evolutionSante),
      appreciations: List.unmodifiable(_appreciations),
    );
  }

  Future<AppreciationAvs> noterAvs({required int note, String? commentaire}) async {
    await _latence();
    final appreciation = AppreciationAvs(
      id: 'appr-${_appreciations.length + 1}',
      note: note,
      commentaire: commentaire,
      date: DateTime.now(),
    );
    _appreciations.insert(0, appreciation);
    return appreciation;
  }

  Future<List<SoinCatalogueItem>> obtenirCatalogueSoins() async {
    await _latence();
    return List.unmodifiable(_catalogue);
  }

  Future<SouscriptionActive?> obtenirSouscriptionActive() async {
    await _latence();
    return _souscriptionActive;
  }

  Future<List<PaiementItem>> obtenirHistoriquePaiements() async {
    await _latence();
    final copie = List<PaiementItem>.from(_paiements);
    copie.sort((a, b) => b.dateTransaction.compareTo(a.dateTransaction));
    return List.unmodifiable(copie);
  }

  /// Simule souscription + paiement via l'API de paiement externe (README
  /// section 3.1). En mock, le paiement "reussit" toujours apres un court
  /// delai, pour permettre de tester tout le parcours ecran par ecran.
  Future<SouscriptionActive> souscrireEtPayer({
    required String soinId,
    required String moyenPaiement,
  }) async {
    await _latence();
    final soin = _catalogue.firstWhere((s) => s.id == soinId);

    final souscription = SouscriptionActive(
      id: 'sousc-${DateTime.now().millisecondsSinceEpoch}',
      soinId: soin.id,
      soinNom: soin.nom,
      dateDebut: DateTime.now(),
      dateFin: DateTime.now().add(const Duration(days: 30)),
      statut: 'active',
    );

    _paiements.insert(
      0,
      PaiementItem(
        id: 'pay-${DateTime.now().millisecondsSinceEpoch}',
        montant: soin.prix,
        statut: 'reussi',
        moyenPaiement: moyenPaiement,
        dateTransaction: DateTime.now(),
        soinNom: soin.nom,
      ),
    );

    _souscriptionActive = souscription;
    return souscription;
  }

  Future<List<MembreFamille>> obtenirMembresFamille() async {
    await _latence();
    return List.unmodifiable(_membresFamille);
  }

  Future<MembreFamille> inviterMembreFamille({
    required String nom,
    required String prenom,
    required String lien,
    required String email,
  }) async {
    await _latence();
    final membre = MembreFamille(
      id: 'user-famille-${_membresFamille.length + 1}',
      nom: nom,
      prenom: prenom,
      lien: lien,
      email: email,
    );
    _membresFamille.add(membre);
    return membre;
  }

  Future<AlerteOuverte> declencherAlerteSos({String? description}) async {
    await _latence();
    final alerte = AlerteOuverte(
      id: 'alerte-${_alertes.length + 1}',
      type: 'sos',
      description: (description != null && description.isNotEmpty) ? description : "Alerte declenchee depuis l'app",
      statut: StatutAlerte.ouverte,
      dateCreation: DateTime.now(),
    );
    _alertes.insert(0, alerte);
    return alerte;
  }

  Future<List<ConversationItem>> obtenirConversations() async {
    await _latence();
    final admin = _messagesParConversation['conv-admin']!;
    final avs = _messagesParConversation['conv-avs']!;

    ConversationItem construire(
      String id,
      TypeInterlocuteur type,
      String titre,
      String? sousTitre,
      List<MessageItem> messages,
    ) {
      final dernier = messages.isEmpty ? null : messages.last;
      return ConversationItem(
        id: id,
        type: type,
        titre: titre,
        sousTitre: sousTitre,
        dernierMessage: dernier?.contenu,
        dateDernierMessage: dernier?.dateEnvoi,
        nonLus: messages.where((m) => !m.lu && !m.envoyeParMoi).length,
      );
    }

    return [
      construire(
        'conv-admin',
        TypeInterlocuteur.administration,
        'Administration SPAD Cameroun',
        'Coordination & suivi',
        admin,
      ),
      construire(
        'conv-avs',
        TypeInterlocuteur.avs,
        _avs.nomComplet,
        'AVS assigne(e)',
        avs,
      ),
    ];
  }

  Future<List<MessageItem>> obtenirMessages(String conversationId) async {
    await _latence();
    final messages = _messagesParConversation[conversationId] ?? const [];
    _messagesParConversation[conversationId] = messages
        .map((m) => MessageItem(
              id: m.id,
              conversationId: m.conversationId,
              contenu: m.contenu,
              dateEnvoi: m.dateEnvoi,
              envoyeParMoi: m.envoyeParMoi,
              lu: true,
            ))
        .toList();
    return List.unmodifiable(_messagesParConversation[conversationId]!);
  }

  Future<MessageItem> envoyerMessage({required String conversationId, required String contenu}) async {
    await _latence();
    final message = MessageItem(
      id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
      conversationId: conversationId,
      contenu: contenu,
      dateEnvoi: DateTime.now(),
      envoyeParMoi: true,
    );
    _messagesParConversation.putIfAbsent(conversationId, () => []).add(message);
    return message;
  }
}
