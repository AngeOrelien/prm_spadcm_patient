import 'package:flutter/material.dart';

import '../../../../shared/widgets/misc/page_en_construction.dart';

/// Onglet 4 — Messagerie interne (UC8 "Utiliser messagerie interne").
/// Affichera les conversations avec l'AVS / le médecin / le coordonnateur
/// une fois `Conversation` / `Message` et Socket.io branchés (Phase 3).
class MessageriePage extends StatelessWidget {
  const MessageriePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messagerie')),
      body: const PageEnConstruction(
        icon: Icons.chat_bubble_outline,
        titre: 'Messagerie',
        description:
            "Vos échanges avec l'équipe soignante (AVS, médecin, "
            'coordonnateur) apparaîtront ici.',
      ),
    );
  }
}
