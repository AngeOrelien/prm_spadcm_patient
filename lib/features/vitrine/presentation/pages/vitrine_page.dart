import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../contact/presentation/pages/contact_page.dart';
import '../../../soins/domain/entities/soins_entities.dart';
import '../../../soins/presentation/providers/soins_providers.dart';
import '../../../soins/presentation/widgets/soin_card.dart';

const List<String> _imagesPresentation = [
  'assets/images/vitrine_presentation_1.jpg',
  'assets/images/vitrine_presentation_2.jpg',
  'assets/images/vitrine_presentation_3.jpg',
  'assets/images/vitrine_presentation_4.jpg',
];

/// Accueil public (README section 3) : présentation SPAD Cameroun +
/// catalogue illustré + formulaire de contact. Point d'atterrissage par
/// défaut d'un utilisateur non connecté (voir `router/app_router.dart`).
class VitrinePage extends ConsumerWidget {
  const VitrinePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showContactSheet(context),
        icon: const Icon(Icons.chat_bubble_outline),
        label: const Text('Une question ?'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(catalogueSoinsProvider),
          child: ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
            children: [
              _AppBarVitrine(onSeConnecter: () => context.push('/login')),
              const _BlocPresentation(),
              const SizedBox(height: AppSpacing.lg),
              const _BlocVideos(),
              const SectionTitleVitrine(titre: 'Nos services'),
              const _CatalogueVitrineSection(),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppBarVitrine extends StatelessWidget {
  final VoidCallback onSeConnecter;

  const _AppBarVitrine({required this.onSeConnecter});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        0,
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/images/logo.png',
            height: 36,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.favorite_outline,
              size: 32,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'SPAD Cameroun',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontSize: 18),
            ),
          ),
          OutlinedButton(
            onPressed: onSeConnecter,
            style: OutlinedButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 8,
              ),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Se connecter'),
          ),
        ],
      ),
    );
  }
}

class _BlocPresentation extends StatelessWidget {
  const _BlocPresentation();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Le suivi de vos proches, à domicile',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            "SPAD Cameroun accompagne les personnes âgées au quotidien : visites d'auxiliaires de vie, "
            'suivi médical, alertes en cas d\'urgence et accès à leur dossier de santé depuis votre téléphone.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _imagesPresentation.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) => ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Image.asset(
                  _imagesPresentation[index],
                  width: 270,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 200,
                    color: AppColors.surfaceMuted,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.image_outlined,
                      color: AppColors.textDisabled,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Section vidéos courtes (README section 3, point 3). Les vidéos sont
/// volontairement décrites plutôt que jouées en boucle sur la page : un
/// tap ouvre le lecteur `video_player` en plein écran pour ne pas charger
/// plusieurs flux vidéo simultanément sur une page qui défile.
class _BlocVideos extends StatelessWidget {
  const _BlocVideos();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Une visite en images',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontSize: 16),
          ),
          const SizedBox(height: AppSpacing.sm),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.play_circle_fill,
                size: 56,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Extrait d'une visite d'auxiliaire de vie à domicile.",
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class SectionTitleVitrine extends StatelessWidget {
  final String titre;

  const SectionTitleVitrine({super.key, required this.titre});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Text(
        titre,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
      ),
    );
  }
}

class _CatalogueVitrineSection extends ConsumerWidget {
  const _CatalogueVitrineSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogueAsync = ref.watch(catalogueSoinsProvider);

    return catalogueAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Text(
          e is AppException ? e.message : 'Erreur de chargement',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
      data: (soins) {
        if (soins.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text('Le catalogue de soins sera bientôt disponible.'),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            children: [
              for (final SoinCatalogue soin in soins)
                SoinCard(
                  soin: soin,
                  onTap: () => context.push('/soins-public/${soin.id}'),
                ),
            ],
          ),
        );
      },
    );
  }
}
