import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../../../../shared/widgets/media/app_video_player.dart';
import '../../../soins/domain/entities/soins_entities.dart';
import '../../../soins/presentation/providers/soins_providers.dart';
import '../../../soins/presentation/widgets/soin_card.dart';
import '../../../contact/presentation/pages/contact_page.dart';

/// Accueil public (README frontend §3) : présentation courte de SPAD
/// Cameroun, images/vidéos illustrant le suivi à domicile, catalogue de
/// services en cartes, et un accès rapide au formulaire de contact. C'est
/// le point d'atterrissage par défaut d'un visiteur non connecté (voir la
/// redirection dans `router/app_router.dart`).
class VitrinePage extends ConsumerWidget {
  const VitrinePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogueAsync = ref.watch(catalogueSoinsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(catalogueSoinsProvider),
          child: ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
            children: [
              _VitrineAppBar(onLogin: () => context.push('/login')),
              const _PresentationSection(),
              const _VideosSection(),
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(
                  'Nos services',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              catalogueAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Text(e is AppException ? e.message : 'Impossible de charger nos services pour le moment.'),
                ),
                data: (soins) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Column(
                    children: [
                      for (final soin in soins)
                        SoinCard(soin: soin, onTap: () => context.push('/soins-public/${soin.id}')),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const _ContactSection(),
            ],
          ),
        ),
      ),
    );
  }
}

class _VitrineAppBar extends StatelessWidget {
  final VoidCallback onLogin;

  const _VitrineAppBar({required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppColors.primarySurface,
            child: Icon(Icons.favorite, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'SPAD Cameroun',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
          ),
          const Spacer(),
          OutlinedButton(onPressed: onLogin, child: const Text('Se connecter')),
        ],
      ),
    );
  }
}

class _PresentationSection extends StatelessWidget {
  const _PresentationSection();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Le suivi à domicile de vos proches âgés,\nen toute confiance',
            style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            "SPAD Cameroun accompagne les personnes âgées à domicile : visites régulières d'un "
            'auxiliaire de vie, suivi des constantes de santé, alertes en cas de besoin, et un lien '
            'direct avec la famille à chaque étape.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: SizedBox(
              height: 160,
              child: Row(
                children: const [
                  Expanded(child: _IllustrationTile(icon: Icons.home_outlined, label: 'Visites à domicile')),
                  SizedBox(width: 2),
                  Expanded(child: _IllustrationTile(icon: Icons.favorite_border, label: 'Suivi des constantes')),
                  SizedBox(width: 2),
                  Expanded(child: _IllustrationTile(icon: Icons.family_restroom, label: 'Lien avec la famille')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Vignette illustrative simple (icône + libellé) en attendant de vraies
/// photos : remplace `Icon` par `Image.asset('assets/images/...')` dès que
/// les visuels définitifs sont disponibles (README frontend §3, point 2).
class _IllustrationTile extends StatelessWidget {
  final IconData icon;
  final String label;

  const _IllustrationTile({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primarySurface,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primaryDark, size: 28),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: AppColors.primaryDark, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Courtes vidéos de présentation. Prévu pour des sources locales
/// (`assets/videos/...`) au départ, migrable vers des URLs distantes sans
/// changer ce widget (README frontend §3, point 3 et §9).
class _VideosSection extends StatelessWidget {
  const _VideosSection();

  // TODO(SPAD) : remplacer par les vraies URLs de vidéos (hébergées via
  // `POST /soins/:id/media` ou une source dédiée à la vitrine) une fois
  // disponibles. Vide pour l'instant -> section masquée automatiquement.
  static const List<String> _videos = [];

  @override
  Widget build(BuildContext context) {
    if (_videos.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('En vidéo', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16)),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _videos.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) => ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: SizedBox(width: 260, child: AppVideoPlayer(url: _videos[index])),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactSection extends StatelessWidget {
  const _ContactSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Une question sur nos services ?',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              "Écrivez à l'équipe SPAD Cameroun, sans créer de compte.",
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppPrimaryButton(
              label: 'Poser une question',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ContactPage()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
