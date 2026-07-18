import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';

/// Contenu générique affiché tant qu'une feature n'a pas encore son écran
/// définitif (Phase 2+ de la feuille de route). Chaque page métier garde
/// son propre fichier/classe (voir `features/<x>/presentation/pages`) pour
/// respecter le découpage `data / domain / presentation` — seul le corps
/// visuel est mutualisé ici pour éviter de dupliquer ce boilerplate.
class PageEnConstruction extends StatelessWidget {
  final IconData icon;
  final String titre;
  final String description;

  const PageEnConstruction({
    super.key,
    required this.icon,
    required this.titre,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: const BoxDecoration(
                color: AppColors.primarySurface,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(titre, style: textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            Text(
              description,
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Bientôt disponible',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textDisabled,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
