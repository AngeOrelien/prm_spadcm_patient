import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../dashboard/presentation/widgets/dashboard_widgets.dart';
import '../../../dossier/presentation/providers/dossier_providers.dart';
import '../../domain/entities/profil_entities.dart';
import '../providers/profil_providers.dart';

/// Onglet 5 — Profil (section 7.1 README) : infos du compte, membres de
/// famille liés au dossier (UC12), sécurité (biométrie).
class ProfilPage extends ConsumerWidget {
  const ProfilPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patient = ref.watch(authControllerProvider).value;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.primarySurface,
            child: Text(
              patient == null || patient.prenom.isEmpty ? '?' : patient.prenom[0].toUpperCase(),
              style: const TextStyle(fontSize: 28, color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Center(child: Text(patient?.nomComplet ?? 'Non connecté', style: Theme.of(context).textTheme.titleLarge)),
          if (patient != null) Center(child: Text(patient.email, style: Theme.of(context).textTheme.bodyMedium)),
          const SizedBox(height: AppSpacing.xl),

          SectionTitle(
            titre: 'Membres de la famille',
            trailing: TextButton.icon(
              onPressed: () => _ouvrirFormulaireInvitation(context, ref),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Ajouter'),
            ),
          ),
          const _MembresFamilleSection(),
          const SizedBox(height: AppSpacing.lg),

          const SectionTitle(titre: 'Compte'),
          _ProfilTile(icon: Icons.person_outline, label: 'Informations personnelles', onTap: () => _ouvrirInfosPatient(context, ref)),
          _ProfilTile(icon: Icons.description_outlined, label: 'Documents médicaux', onTap: () => context.push('/documents')),
          const SizedBox(height: AppSpacing.lg),

          const SectionTitle(titre: 'Sécurité'),
          const _BiometrieTile(),
          _ProfilTile(icon: Icons.notifications_outlined, label: 'Notifications', onTap: () => context.showInfo('Bientôt disponible.')),
          _ProfilTile(icon: Icons.help_outline, label: 'Aide & assistance', onTap: () => context.showInfo('Bientôt disponible.')),

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

  Future<void> _ouvrirInfosPatient(BuildContext context, WidgetRef ref) async {
    final resume = await ref.read(resumePatientProvider.future);
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Informations personnelles'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nom : ${resume.nomComplet}'),
            if (resume.ficheNumero != null) Text('Fiche n° : ${resume.ficheNumero}'),
            if (resume.age != null) Text('Âge : ${resume.age} ans'),
            if (resume.ville != null) Text('Ville : ${resume.ville}${resume.quartier != null ? ', ${resume.quartier}' : ''}'),
            if (resume.contactUrgence?.nom != null)
              Text('Contact urgence : ${resume.contactUrgence!.nom} (${resume.contactUrgence!.lien ?? '—'})'),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Fermer'))],
      ),
    );
  }

  Future<void> _ouvrirFormulaireInvitation(BuildContext context, WidgetRef ref) async {
    final nomController = TextEditingController();
    final prenomController = TextEditingController();
    final lienController = TextEditingController();
    final emailController = TextEditingController();

    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter un membre de la famille'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: prenomController, decoration: const InputDecoration(labelText: 'Prénom')),
            TextField(controller: nomController, decoration: const InputDecoration(labelText: 'Nom')),
            TextField(controller: lienController, decoration: const InputDecoration(labelText: 'Lien de parenté (ex: Fille)')),
            TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Inviter')),
        ],
      ),
    );

    if (confirme != true || !context.mounted) return;
    if (nomController.text.trim().isEmpty || emailController.text.trim().isEmpty) {
      context.showError('Nom et email sont obligatoires.');
      return;
    }

    final succes = await ref.read(invitationMembreControllerProvider.notifier).inviter(
          nom: nomController.text.trim(),
          prenom: prenomController.text.trim(),
          lien: lienController.text.trim().isEmpty ? 'Proche' : lienController.text.trim(),
          email: emailController.text.trim(),
        );
    if (!context.mounted) return;
    if (succes) {
      context.showInfo('Invitation envoyée à ${emailController.text.trim()}.');
    } else {
      context.showError("L'invitation a échoué, réessayez.");
    }
  }
}

class _MembresFamilleSection extends ConsumerWidget {
  const _MembresFamilleSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membresAsync = ref.watch(membresFamilleProvider);
    return membresAsync.when(
      loading: () => const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: LinearProgressIndicator()),
      error: (e, _) => Text(e is AppException ? e.message : 'Erreur de chargement'),
      data: (membres) => Column(
        children: [for (final membre in membres) _MembreFamilleTile(membre: membre)],
      ),
    );
  }
}

class _MembreFamilleTile extends StatelessWidget {
  final MembreFamille membre;

  const _MembreFamilleTile({required this.membre});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primarySurface,
            child: Text(membre.prenom.isEmpty ? '?' : membre.prenom[0].toUpperCase(), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(membre.nomComplet, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(membre.lien, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          if (membre.estCompteConnecte) const StatusChip(label: 'Vous', couleur: AppColors.primary),
        ],
      ),
    );
  }
}

class _BiometrieTile extends ConsumerWidget {
  const _BiometrieTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(biometrieActiveProvider);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.fingerprint, color: AppColors.textSecondary),
      title: const Text('Connexion par biométrie'),
      subtitle: const Text('Empreinte digitale ou reconnaissance faciale'),
      trailing: Switch(
        value: active,
        onChanged: (value) {
          ref.read(biometrieActiveProvider.notifier).state = value;
          ref.read(profilRemoteDataSourceProvider).definirBiometrie(value);
          context.showInfo(value ? 'Biométrie activée.' : 'Biométrie désactivée.');
        },
      ),
    );
  }
}

class _ProfilTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ProfilTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textDisabled),
      onTap: onTap,
    );
  }
}
