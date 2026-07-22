import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../domain/entities/dashboard_entities.dart';

/// Petite carte de statistique (ex: "2 Traitements en cours"), même style
/// que côté app Personnel (`StatCard`).
class StatCard extends StatelessWidget {
  final String valeur;
  final String libelle;
  final IconData icon;
  final Color couleur;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.valeur,
    required this.libelle,
    required this.icon,
    required this.couleur,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: couleur.withOpacity(0.12), shape: BoxShape.circle),
                child: Icon(icon, color: couleur, size: 18),
              ),
              const SizedBox(height: 6),
              Text(
                valeur,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 20),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                libelle,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Titre de section réutilisé sur toute la page d'accueil.
class SectionTitle extends StatelessWidget {
  final String titre;
  final Widget? trailing;

  const SectionTitle({super.key, required this.titre, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
      child: Row(
        children: [
          Expanded(child: Text(titre, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16))),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Badge/chip de statut (ex: statut d'une alerte).
class StatusChip extends StatelessWidget {
  final String label;
  final Color couleur;

  const StatusChip({super.key, required this.label, required this.couleur});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: couleur.withOpacity(0.12), borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Text(
        label,
        style: TextStyle(color: couleur, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Une carte "vide" avec icône + message, utilisée quand une section n'a
/// encore aucune donnée (ex: pas encore de rapport de soins).
class EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String message;

  const EmptyStateCard({super.key, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textDisabled, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(message, style: Theme.of(context).textTheme.bodySmall),
            ),
          ],
        ),
      ),
    );
  }
}

/// Une valeur de constante vitale (ex: "Pouls · 78 bpm"), utilisée dans la
/// carte "Dernières constantes".
class ConstanteChip extends StatelessWidget {
  final IconData icon;
  final String libelle;
  final String? valeur;

  const ConstanteChip({super.key, required this.icon, required this.libelle, this.valeur});

  @override
  Widget build(BuildContext context) {
    final estRenseigne = valeur != null && valeur!.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.primaryDark),
              const SizedBox(width: 4),
              Text(libelle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            estRenseigne ? valeur! : '—',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

extension StatutAlerteX on StatutAlerte {
  String get libelle => switch (this) {
        StatutAlerte.ouverte => 'Ouverte',
        StatutAlerte.enCours => 'Prise en charge',
        StatutAlerte.resolue => 'Résolue',
      };

  Color get couleur => switch (this) {
        StatutAlerte.ouverte => AppColors.sos,
        StatutAlerte.enCours => AppColors.warning,
        StatutAlerte.resolue => AppColors.success,
      };
}
