import 'package:flutter/material.dart';

import '../../../../shared/widgets/misc/page_en_construction.dart';

/// Onglet 2 — Journal de soins (UC3 "Consulter journal de soins").
/// Affichera l'historique des `RapportJournalier` saisis par les AVS
/// (constantes, checklist de soins, observations) une fois l'API rapports
/// disponible côté backend (Phase 2 de la feuille de route).
class JournalSoinsPage extends StatelessWidget {
  const JournalSoinsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Journal de soins')),
      body: const PageEnConstruction(
        icon: Icons.medical_information_outlined,
        titre: 'Journal de soins',
        description:
            "L'historique des visites et des rapports quotidiens de l'AVS "
            'apparaîtra ici, avec le détail des soins prodigués.',
      ),
    );
  }
}
