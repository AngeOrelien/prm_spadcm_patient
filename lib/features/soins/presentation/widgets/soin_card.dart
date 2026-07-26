import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../dashboard/presentation/widgets/dashboard_widgets.dart';
import '../../domain/entities/soins_entities.dart';

String prixFormate(int prix) =>
    '${prix.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} FCFA';

/// Carte de soin factorisée, utilisée à la fois par la vitrine publique
/// (`/vitrine`) et par l'onglet Soins authentifié (`soins_page.dart`), pour
/// ne pas dupliquer le style entre les deux écrans (README section 3).
///
/// - [onTap] : tap sur la carte entière, pousse vers l'écran de détail
///   (public ou privé selon le contexte appelant).
/// - [estActif] : le patient est déjà souscrit à ce soin précis (affiche le
///   badge "Votre forfait").
/// - [footer] : zone d'action optionnelle en bas de carte (bouton
///   "Souscrire"/"Souscrit" côté onglet Soins authentifié). `null` sur la
///   vitrine, où le tap sur la carte suffit — pas de bouton d'action actif
///   avant connexion.
class SoinCard extends StatelessWidget {
  final SoinCatalogue soin;
  final bool estActif;
  final VoidCallback? onTap;
  final Widget? footer;

  const SoinCard({
    super.key,
    required this.soin,
    this.estActif = false,
    this.onTap,
    this.footer,
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
              if (soin.imageCouverture != null)
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    soin.imageCouverture!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppColors.surfaceMuted,
                      alignment: Alignment.center,
                      child: const Icon(Icons.medical_information_outlined, color: AppColors.textDisabled, size: 36),
                    ),
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(color: AppColors.surfaceMuted, height: double.infinity);
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
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        const Icon(Icons.event_repeat_outlined, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text(soin.frequenceVisites, style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                    if (soin.prestationsIncluses.isNotEmpty) ...[
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
                    ],
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Text(
                          '${prixFormate(soin.prix)} / mois',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16, color: AppColors.primaryDark),
                        ),
                        const Spacer(),
                        if (footer != null) footer!,
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
