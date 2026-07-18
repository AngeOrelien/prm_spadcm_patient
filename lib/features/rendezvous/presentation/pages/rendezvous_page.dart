import 'package:flutter/material.dart';

import '../../../../shared/widgets/misc/page_en_construction.dart';

/// Onglet 3 — Calendrier des rendez-vous (UC6 "Consulter calendrier RDV").
/// Affichera les `RendezVous` à venir (visites AVS, consultations médecin,
/// prescriptions) une fois l'API correspondante disponible.
class RendezVousPage extends StatelessWidget {
  const RendezVousPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rendez-vous')),
      body: const PageEnConstruction(
        icon: Icons.calendar_month_outlined,
        titre: 'Calendrier des rendez-vous',
        description:
            'Les prochaines visites, consultations et rappels de prescription '
            'apparaîtront ici.',
      ),
    );
  }
}
