import 'package:flutter/material.dart';

import '../../../../shared/widgets/misc/page_en_construction.dart';

/// Documents médicaux (UC5 "Consulter documents médicaux").
///
/// Volontairement **hors de la bottom navigation** : c'est une consultation
/// ponctuelle plutôt qu'un usage quotidien, donc accessible en push depuis
/// l'Accueil ou le Profil plutôt que de consommer un onglet. Affichera les
/// `DocumentMedical` (ordonnances, comptes rendus, résultats d'analyses).
class DocumentsPage extends StatelessWidget {
  const DocumentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Documents médicaux')),
      body: const PageEnConstruction(
        icon: Icons.folder_shared_outlined,
        titre: 'Documents médicaux',
        description:
            'Ordonnances, comptes rendus et résultats d\'analyses partagés '
            'par l\'équipe soignante apparaîtront ici.',
      ),
    );
  }
}
