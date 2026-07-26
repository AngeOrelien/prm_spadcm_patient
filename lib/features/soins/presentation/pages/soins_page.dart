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

/// Onglet 2 — Soins (section 7.1 README) : recherche/catalogue de soins,
/// souscription, historique des paiements.
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
        title: const Text('Mettre fin à votre souscription ?'),
        content: Text(
          souscription.statut == StatutSouscription.active
              ? 'Vous pourrez souscrire à un autre soin juste après.'
              : 'Cette souscription en attente de paiement sera annulée.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Confirmer')),
        ],
      ),
    );
    if (confirme != true || !context.mounted) return;

    final controller = ref.read(terminerSouscriptionControllerProvider.notifier);
    final succes = souscription.statut == StatutSouscription.active
        ? await controller.terminer(souscription.id)
        : await controller.annuler(souscription.id);

    if (!context.mounted) return;
    if (succes) {
      context.showInfo('Votre souscription a été mise à jour.');
    } else {
      final erreur = ref.read(terminerSouscriptionControllerProvider).asError?.error;
      context.showError(erreur is AppException ? erreur.message : 'Une erreur est survenue.');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final souscriptionsAsync = ref.watch(souscriptionsProvider);
    final isLoadingAction = ref.watch(terminerSouscriptionControllerProvider).isLoading;

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
        if (souscriptions.isEmpty) {
          return const EmptyStateCard(
            icon: Icons.medical_information_outlined,
            message: "Aucune souscription active. Choisissez un forfait dans le catalogue ci-dessous.",
          );
        }
        final souscription = souscriptions.first;
        final estActive = souscription.statut == StatutSouscription.active;
        final enAttente = souscription.statut == StatutSouscription.enAttentePaiement;
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
                      label: estActive ? 'Active' : (enAttente ? 'En attente de paiement' : 'Expirée'),
                      couleur: estActive ? AppColors.success : AppColors.warning,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('${prixFormate(souscription.soinPrix)} / mois', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 4),
                if (souscription.dateFin != null)
                  Text(
                    'Renouvellement le ${_dateCourte(souscription.dateFin!)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                if (estActive || enAttente) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: isLoadingAction ? null : () => _terminer(context, ref, souscription),
                      icon: const Icon(Icons.close, size: 18, color: AppColors.error),
                      label: const Text('Mettre fin à ma souscription', style: TextStyle(color: AppColors.error)),
                    ),
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
    final soinActifId = souscriptions.isNotEmpty ? souscriptions.first.soinId : null;

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
                estActif: soin.id == soinActifId,
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
                  prixFormate(paiement.montant),
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
