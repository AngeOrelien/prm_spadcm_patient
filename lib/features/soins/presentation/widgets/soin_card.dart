import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../dashboard/presentation/widgets/dashboard_widgets.dart';
import '../../domain/entities/soins_entities.dart';

String prixFormatte(int prix) =>
    '${prix.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} FCFA';

/// Carte de présentation d'un [SoinCatalogue], utilisée à la fois sur la
/// vitrine publique (`/vitrine`) et sur l'onglet Soins authentifié
/// (`/soins`) — un seul style de carte pour les deux contextes (README
/// frontend §3 et §8). Le tap sur la carte entière pousse vers l'écran de
/// détail ; `trailingAction` permet à l'onglet authentifié d'ajouter un
/// bouton "Souscrire"/"Souscrit" en plus du tap.
class SoinCard extends StatelessWidget {
  final SoinCatalogue soin;
  final bool estActif;
  final VoidCallback? onTap;
  final Widget? trailingAction;

  const SoinCard({
    super.key,
    required this.soin,
    this.estActif = false,
    this.onTap,
    this.trailingAction,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: estActif ? AppColors.primary : AppColors.border, width: estActif ? 1.5 : 1),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (soin.imageCouverture != null && soin.imageCouverture!.isNotEmpty)
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    soin.imageCouverture!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppColors.surfaceMuted,
                      alignment: Alignment.center,
                      child: const Icon(Icons.medical_information_outlined, color: AppColors.textDisabled, size: 32),
                    ),
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        color: AppColors.surfaceMuted,
                        alignment: Alignment.center,
                        child: const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
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
                    Text(
                      soin.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        const Icon(Icons.event_repeat_outlined, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(soin.frequenceVisites, style: Theme.of(context).textTheme.bodySmall),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Text(
                          '${prixFormatte(soin.prix)} / mois',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontSize: 16, color: AppColors.primaryDark),
                        ),
                        const Spacer(),
                        if (trailingAction != null) trailingAction!,
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
