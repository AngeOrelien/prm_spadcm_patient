import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';

/// Coquille (shell) de la bottom navigation du patient, câblée sur
/// `StatefulShellRoute.indexedStack` dans `router/app_router.dart` : chaque
/// onglet garde sa propre pile de navigation et son propre état lorsqu'on
/// bascule de l'un à l'autre.
///
/// 5 onglets (section 7.1 du README) : Accueil (UC2), Soins — catalogue,
/// souscription, paiements (UC3), Dossier — dossier médical complet :
/// antécédents, traitements, rapports journaliers, documents, calendrier
/// RDV, évolution IA, notation de l'AVS (UC5/UC6/UC7), Messages — deux fils
/// Administration/AVS (UC8), Profil — compte, famille, sécurité (UC12). Le
/// bouton SOS (UC4) — l'action la plus critique de l'app — n'est
/// volontairement PAS un onglet : c'est un bouton flottant permanent
/// (`FloatingActionButton.extended`, `centerFloat`), toujours visible et
/// atteignable en un geste quel que soit l'onglet actif, plutôt que de
/// partager l'attention avec le reste de la navigation.
class PatientShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const PatientShell({super.key, required this.navigationShell});

  static const _destinations = [
    _NavItem(icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Accueil'),
    _NavItem(icon: Icons.medical_information_outlined, selectedIcon: Icons.medical_information, label: 'Soins'),
    _NavItem(icon: Icons.folder_shared_outlined, selectedIcon: Icons.folder_shared, label: 'Dossier'),
    _NavItem(icon: Icons.chat_bubble_outline, selectedIcon: Icons.chat_bubble, label: 'Messages'),
    _NavItem(icon: Icons.person_outline, selectedIcon: Icons.person, label: 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'sos-fab',
        backgroundColor: AppColors.sos,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.sos_rounded),
        label: const Text('SOS', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => context.push('/sos'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          // Revient à la racine de l'onglet si on tape dessus alors qu'il
          // est déjà actif (comportement standard des bottom nav mobiles).
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: [
          for (final item in _destinations)
            NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.selectedIcon),
              label: item.label,
            ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _NavItem({required this.icon, required this.selectedIcon, required this.label});
}
