import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../dashboard/presentation/widgets/dashboard_widgets.dart';
import '../../domain/entities/soins_entities.dart';
import '../providers/soins_providers.dart';

const _mois = [
  'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
  'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
];

String _dateCourte(DateTime date) => '${date.day} ${_mois[date.month - 1]}  ${date.year}';

String _prix(int prix) => '${prix.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} FCFA';

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final souscriptionsAsync = ref.watch(souscriptionsProvider);
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
                      label: souscription.statut == StatutSouscription.active ? 'Active' : 'Expirée',
                      couleur: souscription.statut == StatutSouscription.active ? AppColors.success : AppColors.warning,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('${_prix(souscription.soinPrix)} / mois', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 4),
                if (souscription.dateFin != null)
                  Text(
                    'Renouvellement le ${_dateCourte(souscription.dateFin!)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
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
    final soinActifNom = souscriptions.isNotEmpty ? souscriptions.first.soinNom : null;

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
              _SoinCard(soin: soin, estActif: soin.nom == soinActifNom),
          ],
        ),
      ),
    );
  }
}

class _SoinCard extends ConsumerWidget {
  final SoinCatalogue soin;
  final bool estActif;

  const _SoinCard({required this.soin, required this.estActif});

  Future<void> _confirmerSouscription(BuildContext context, WidgetRef ref) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la souscription'),
        content: Text(
          'Souscrire au forfait "${soin.nom}" pour ${_prix(soin.prix)}/mois ? '
          'Le paiement sera effectué via mobile money.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Payer et souscrire')),
        ],
      ),
    );
    if (confirme != true || !context.mounted) return;

    final succes = await ref.read(souscriptionControllerProvider.notifier).souscrire(soin.id);
    if (!context.mounted) return;
    if (succes) {
      context.showInfo('Souscription confirmée, paiement effectué avec succès.');
    } else {
      context.showError('Le paiement a échoué, réessayez.');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(souscriptionControllerProvider).isLoading;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: estActif ? AppColors.primary : AppColors.border, width: estActif ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(soin.nom, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16)),
              ),
              if (estActif) const StatusChip(label: 'Votre forfait', couleur: AppColors.primary),
            ],
          ),
          const SizedBox(height: 4),
          Text(soin.description, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(Icons.event_repeat_outlined, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(soin.frequenceVisites, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final prestation in soin.prestationsIncluses)
                Chip(
                  label: Text(prestation, style: const TextStyle(fontSize: 11)),
                  backgroundColor: AppColors.surfaceMuted,
                  visualDensity: VisualDensity.compact,
                  side: BorderSide.none,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Text(
                '${_prix(soin.prix)} / mois',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16, color: AppColors.primaryDark),
              ),
              const Spacer(),
              FilledButton(
                onPressed: estActif || isLoading ? null : () => _confirmerSouscription(context, ref),
                child: Text(estActif ? 'Souscrit' : 'Souscrire'),
              ),
            ],
          ),
        ],
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
                  '${_prix(paiement.montant)}',
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
