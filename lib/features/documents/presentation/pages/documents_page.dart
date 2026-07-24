import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../dashboard/presentation/widgets/dashboard_widgets.dart';
import '../../../dossier/domain/entities/dossier_entities.dart';
import '../../../dossier/presentation/providers/dossier_providers.dart';

const _mois = [
  'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
  'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
];

String _dateCourte(DateTime date) => '${date.day} ${_mois[date.month - 1]} ${date.year}';

/// Documents médicaux (UC5 "Consulter documents médicaux").
///
/// Volontairement **hors de la bottom navigation** : c'est une consultation
/// ponctuelle plutôt qu'un usage quotidien, accessible en push depuis
/// l'onglet Dossier ou l'Accueil. Réutilise le même provider que la section
/// "Documents médicaux" du Dossier (`documentsMedicauxProvider`) pour rester
/// cohérent avec le futur `GET /patients/moi/documents`.
class DocumentsPage extends ConsumerWidget {
  const DocumentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(documentsMedicauxProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Documents médicaux')),
      body: docsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(e is AppException ? e.message : 'Une erreur est survenue.'),
          ),
        ),
        data: (docs) {
          if (docs.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: EmptyStateCard(
                icon: Icons.folder_shared_outlined,
                message:
                    "Ordonnances, comptes rendus et résultats d'analyses partagés par l'équipe soignante "
                    'apparaîtront ici.',
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) => _DocumentCard(document: docs[index]),
          );
        },
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final DocumentMedicalDossier document;

  const _DocumentCard({required this.document});

  (IconData, String) get _typeInfo => switch (document.type) {
        'ordonnance' => (Icons.receipt_long_outlined, 'Ordonnance'),
        'analyse' => (Icons.science_outlined, "Résultat d'analyse"),
        'compte_rendu' => (Icons.article_outlined, 'Compte rendu'),
        _ => (Icons.description_outlined, 'Document'),
      };

  @override
  Widget build(BuildContext context) {
    final (icon, libelle) = _typeInfo;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: AppColors.primarySurface, shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.primaryDark, size: 20),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.nomFichier ?? libelle,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                Text('$libelle · ajouté le ${_dateCourte(document.dateAjout)}', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.download_outlined, color: AppColors.primary),
            tooltip: 'Ouvrir',
            onPressed: () => context.showInfo('Ouverture du document bientôt disponible.'),
          ),
        ],
      ),
    );
  }
}
