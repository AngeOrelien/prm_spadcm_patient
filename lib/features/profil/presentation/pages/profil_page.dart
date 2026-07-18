import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Onglet 5 — Profil & sécurité (UC7 "Gérer profil & sécurité").
/// La déconnexion est déjà fonctionnelle (elle prouve que l'auth persiste
/// correctement) ; le reste (édition du profil, biométrie, changement de
/// mot de passe) viendra avec la Phase 1 mobile de la feuille de route.
class ProfilPage extends ConsumerWidget {
  const ProfilPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patient = ref.watch(authControllerProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.primarySurface,
            child: Text(
              patient == null || patient.prenom.isEmpty
                  ? '?'
                  : patient.prenom[0].toUpperCase(),
              style: const TextStyle(fontSize: 28, color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: Text(
              patient?.nomComplet ?? 'Non connecté',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          if (patient != null)
            Center(
              child: Text(patient.email, style: Theme.of(context).textTheme.bodyMedium),
            ),
          const SizedBox(height: AppSpacing.xl),

          const _ProfilTile(icon: Icons.person_outline, label: 'Informations personnelles'),
          const _ProfilTile(icon: Icons.description_outlined, label: 'Documents médicaux'),
          const _ProfilTile(icon: Icons.fingerprint, label: 'Sécurité & biométrie'),
          const _ProfilTile(icon: Icons.notifications_outlined, label: 'Notifications'),
          const _ProfilTile(icon: Icons.help_outline, label: 'Aide & assistance'),

          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            onPressed: () => ref.read(authControllerProvider.notifier).deconnecter(),
            icon: const Icon(Icons.logout, color: AppColors.error),
            label: const Text('Déconnexion', style: TextStyle(color: AppColors.error)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _ProfilTile extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ProfilTile({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textDisabled),
      onTap: () {}, // Bientôt disponible
    );
  }
}
