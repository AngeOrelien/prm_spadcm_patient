import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../dashboard/presentation/widgets/dashboard_widgets.dart';
import '../../domain/entities/soins_entities.dart';
import '../providers/soins_providers.dart';
import '../widgets/soin_card.dart';

const _mois = [
  'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
  'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
];

String _dateCourte(DateTime date) => '${date.day} ${_mois[date.month - 1]}  ${date.year}';

/// Onglet 2 — Soins (section 7.1 README) : recherche/catalogue de soins
/// illustré, souscription (avec formulaire patientInfo + paiement),
/// historique des paiements. C'est ce que le README frontend appelle
/// l'onglet "services".
class SoinsPage extends ConsumerWidget {
  const SoinsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Soins')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(catalogueSoinsProvider);
          ref.invalidate(souscriptionsProvider);
          ref.invalidate(paiementsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
          children: [
            const SectionTitle(titre: 'Votre souscription'),
            const _SouscriptionActiveSection(),
            const SectionTitle(titre: 'Catalogue de soins'),
            const _CatalogueSection(),
            const SectionTitle(titre: 'Historique des paiements'),
            const _HistoriquePaiementsSection(),
          ],
        ),
      ),
    );
  }
}

class _SouscriptionActiveSection extends ConsumerWidget {
  const _SouscriptionActiveSection();

  Future<void> _terminer(BuildContext context, WidgetRef ref, Souscription souscription) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mettre fin à votre souscription'),
        content: Text(
          'Mettre fin à "${souscription.soinNom}" maintenant ? Vous pourrez alors souscrire à un '
          'autre service, mais le suivi actuel s\'arrêtera.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Confirmer')),
        ],
      ),
    );
    if (confirme != true || !context.mounted) return;

    final succes = await ref.read(terminerSouscriptionControllerProvider.notifier).terminer(souscription.id);
    if (!context.mounted) return;
    if (succes) {
      context.showInfo('Souscription terminée.');
    } else {
      context.showError('Impossible de terminer la souscription, réessayez.');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final souscriptionsAsync = ref.watch(souscriptionsProvider);
    final terminerLoading = ref.watch(terminerSouscriptionControllerProvider).isLoading;

    return souscriptionsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: LinearProgressIndicator(),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Text(e is AppException ? e.message : 'Erreur de chargement', style: Theme.of(context).textTheme.bodySmall),
      ),
      data: (souscriptions) {
        final active = souscriptions.where((s) => s.estBloquante).toList();
        if (active.isEmpty) {
          return const EmptyStateCard(
            icon: Icons.medical_information_outlined,
            message: "Aucune souscription active. Choisissez un forfait dans le catalogue ci-dessous.",
          );
        }
        final souscription = active.first;
        final estActive = souscription.statut == StatutSouscription.active;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 6),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.primaryLight.withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        souscription.soinNom,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
                      ),
                    ),
                    StatusChip(
                      label: estActive ? 'Active' : 'En attente de paiement',
                      couleur: estActive ? AppColors.success : AppColors.warning,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('${prixFormatte(souscription.soinPrix)} / mois', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 4),
                if (souscription.dateFin != null)
                  Text(
                    'Renouvellement le ${_dateCourte(souscription.dateFin!)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                if (estActive) ...[
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton(
                    onPressed: terminerLoading ? null : () => _terminer(context, ref, souscription),
                    child: terminerLoading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Mettre fin à ma souscription'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CatalogueSection extends ConsumerWidget {
  const _CatalogueSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogueAsync = ref.watch(catalogueSoinsProvider);
    final souscriptions = ref
        .watch(souscriptionsProvider)
        .maybeWhen(data: (d) => d, orElse: () => const <Souscription>[]);
    final soinIdActif = souscriptions
        .where((s) => s.estBloquante)
        .map((s) => s.soinId)
        .firstWhere((id) => id != null, orElse: () => null);

    return catalogueAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Text(e is AppException ? e.message : 'Erreur de chargement'),
      ),
      data: (soins) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          children: [
            for (final soin in soins)
              SoinCard(
                soin: soin,
                estActif: soin.id == soinIdActif,
                onTap: () => context.push('/soins/${soin.id}'),
              ),
          ],
        ),
      ),
    );
  }
}

class _HistoriquePaiementsSection extends ConsumerWidget {
  const _HistoriquePaiementsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paiementsAsync = ref.watch(paiementsProvider);
    return paiementsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: LinearProgressIndicator(),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Text(e is AppException ? e.message : 'Erreur de chargement'),
      ),
      data: (paiements) {
        if (paiements.isEmpty) {
          return const EmptyStateCard(icon: Icons.receipt_long_outlined, message: 'Aucun paiement enregistré.');
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            children: [
              for (final paiement in paiements) _PaiementTile(paiement: paiement),
            ],
          ),
        );
      },
    );
  }
}

class _PaiementTile extends StatelessWidget {
  final Paiement paiement;

  const _PaiementTile({required this.paiement});

  @override
  Widget build(BuildContext context) {
    final reussi = paiement.statut == StatutPaiement.reussi;
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (reussi ? AppColors.success : AppColors.error).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              reussi ? Icons.check_circle_outline : Icons.error_outline,
              color: reussi ? AppColors.success : AppColors.error,
              size: 18,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prixFormatte(paiement.montant),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                Text(
                  '${_dateCourte(paiement.dateTransaction)} · ${paiement.referenceExterne}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
