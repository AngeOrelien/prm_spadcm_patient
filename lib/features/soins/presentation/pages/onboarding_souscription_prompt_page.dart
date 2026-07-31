import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../providers/soins_providers.dart';
import '../widgets/soin_card.dart';

/// Dernière étape de l'onboarding : le dossier vient d'être créé, on
/// propose immédiatement une souscription à un suivi SPAD (README —
/// "espace de souscription proposé juste après le dossier"), sans jamais
/// bloquer l'accès à l'app si le patient préfère y revenir plus tard.
class OnboardingSouscriptionPromptPage extends ConsumerWidget {
  const OnboardingSouscriptionPromptPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogueAsync = ref.watch(catalogueSoinsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Choisir un suivi'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Votre dossier est prêt 🎉', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text(
                    "Souscrivez dès maintenant à un suivi SPAD à domicile, ou passez cette étape — vous pourrez le faire à tout moment depuis l'onglet Soins.",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Expanded(
              child: catalogueAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text(e is AppException ? e.message : 'Impossible de charger le catalogue.'),
                  ),
                ),
                data: (soins) {
                  if (soins.isEmpty) {
                    return const Center(child: Text('Aucun soin disponible pour le moment.'));
                  }
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl),
                    children: [
                      for (final soin in soins)
                        SoinCard(
                          soin: soin,
                          onTap: () => context.push('/soins/souscrire/${soin.id}'),
                          footer: FilledButton(
                            onPressed: () => context.push('/soins/souscrire/${soin.id}'),
                            child: const Text('Souscrire'),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
                child: TextButton(
                  onPressed: () => context.go('/accueil'),
                  child: const Text('Plus tard, aller à mon espace'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
