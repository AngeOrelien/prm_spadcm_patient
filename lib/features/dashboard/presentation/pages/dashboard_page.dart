import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/misc/page_en_construction.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Onglet 1 — Tableau de bord santé (UC2 "Consulter tableau de bord santé").
/// Sera le point d'entrée vers : constantes récentes, dernier rapport AVS,
/// résumé IA, et accès rapide aux documents médicaux (UC5).
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patient = ref.watch(authControllerProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accueil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.description_outlined),
            tooltip: 'Documents médicaux',
            onPressed: () => context.push('/documents'),
          ),
        ],
      ),
      body: PageEnConstruction(
        icon: Icons.favorite_outline,
        titre: patient == null
            ? 'Tableau de bord santé'
            : 'Bonjour ${patient.prenom}',
        description:
            "L'état de santé de votre proche, les constantes récentes et le "
            'résumé du dernier rapport de soins apparaîtront ici.',
      ),
    );
  }
}
