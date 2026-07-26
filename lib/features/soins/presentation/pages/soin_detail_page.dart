import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/soins_entities.dart';
import '../providers/soins_providers.dart';
import '../widgets/soin_card.dart';

/// Détail d'un soin, réutilisé dans deux contextes (README section 6.2) :
/// - public, poussé depuis `/soins-public/:id` (vitrine, non connecté) ;
/// - privé, poussé depuis `/soins/:id` (onglet Soins authentifié).
///
/// [estContextePublic] ne change que le comportement du bouton du bas —
/// tout le reste du rendu (image, galerie, vidéos, description) est
/// identique dans les deux contextes.
class SoinDetailPage extends ConsumerWidget {
  final String soinId;
  final bool estContextePublic;

  const SoinDetailPage({super.key, required this.soinId, this.estContextePublic = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final soinAsync = ref.watch(soinProvider(soinId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Détail du soin')),
      body: soinAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(e is AppException ? e.message : 'Impossible de charger ce soin.'),
          ),
        ),
        data: (soin) => _SoinDetailContent(soin: soin, estContextePublic: estContextePublic),
      ),
    );
  }
}

class _SoinDetailContent extends ConsumerWidget {
  final SoinCatalogue soin;
  final bool estContextePublic;

  const _SoinDetailContent({required this.soin, required this.estContextePublic});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final estConnecte = authState.value != null;

    final souscriptions = ref
        .watch(souscriptionsProvider)
        .maybeWhen(data: (d) => d, orElse: () => const <Souscription>[]);
    final souscriptionEnCours = souscriptions.isEmpty ? null : souscriptions.first;
    final estDejaSouscritACeSoin = souscriptionEnCours?.soinId == soin.id;
    final aUneAutreSouscription = souscriptionEnCours != null && !estDejaSouscritACeSoin;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
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
                      child: const Icon(Icons.medical_information_outlined, size: 48, color: AppColors.textDisabled),
                    ),
                  ),
                ),
              if (soin.images.length > 1)
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                    scrollDirection: Axis.horizontal,
                    itemCount: soin.images.length,
                    separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (context, index) => ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: Image.network(
                        soin.images[index],
                        width: 140,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 140,
                          color: AppColors.surfaceMuted,
                        ),
                      ),
                    ),
                  ),
                ),
              if (soin.videos.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Vidéo de présentation', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 15)),
                      const SizedBox(height: AppSpacing.sm),
                      for (final video in soin.videos) _InlineVideoPlayer(url: video),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(soin.nom, style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: AppSpacing.sm),
                    Text(soin.description, style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        const Icon(Icons.event_repeat_outlined, size: 18, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text(soin.frequenceVisites, style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                    if (soin.prestationsIncluses.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text('Prestations incluses', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 15)),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final prestation in soin.prestationsIncluses)
                            Chip(label: Text(prestation), backgroundColor: AppColors.surfaceMuted, side: BorderSide.none),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      '${prixFormate(soin.prix)} / mois',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.primaryDark),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
            child: _BoutonAction(
              soin: soin,
              estConnecte: estConnecte,
              estDejaSouscritACeSoin: estDejaSouscritACeSoin,
              aUneAutreSouscription: aUneAutreSouscription,
              souscriptionEnCours: souscriptionEnCours,
            ),
          ),
        ),
      ],
    );
  }
}

class _BoutonAction extends ConsumerWidget {
  final SoinCatalogue soin;
  final bool estConnecte;
  final bool estDejaSouscritACeSoin;
  final bool aUneAutreSouscription;
  final Souscription? souscriptionEnCours;

  const _BoutonAction({
    required this.soin,
    required this.estConnecte,
    required this.estDejaSouscritACeSoin,
    required this.aUneAutreSouscription,
    required this.souscriptionEnCours,
  });

  Future<void> _terminerAutreSouscription(BuildContext context, WidgetRef ref) async {
    if (souscriptionEnCours == null) return;
    final controller = ref.read(terminerSouscriptionControllerProvider.notifier);
    final estActive = souscriptionEnCours!.statut == StatutSouscription.active;
    final succes = estActive
        ? await controller.terminer(souscriptionEnCours!.id)
        : await controller.annuler(souscriptionEnCours!.id);
    if (!context.mounted) return;
    if (succes) {
      context.showInfo('Souscription précédente terminée, vous pouvez souscrire à ce soin.');
    } else {
      final erreur = ref.read(terminerSouscriptionControllerProvider).asError?.error;
      context.showError(erreur is AppException ? erreur.message : 'Une erreur est survenue.');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!estConnecte) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton(
          onPressed: () => context.push('/inscription', extra: {'soinId': soin.id}),
          child: const Text('Souscrire'),
        ),
      );
    }

    if (estDejaSouscritACeSoin) {
      return const SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton(onPressed: null, child: Text('Déjà souscrit')),
      );
    }

    if (aUneAutreSouscription) {
      final isLoading = ref.watch(terminerSouscriptionControllerProvider).isLoading;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Vous avez déjà une souscription en cours à un autre soin. '
            'Mettez-y fin avant de souscrire à celui-ci.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: isLoading ? null : () => _terminerAutreSouscription(context, ref),
              child: isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5))
                  : const Text('Mettre fin à ma souscription en cours'),
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: () => context.push('/soins/souscrire/${soin.id}'),
        child: const Text('Souscrire'),
      ),
    );
  }
}

/// Lecteur vidéo minimal (`video_player`) pour les courtes vidéos illustrant
/// un soin. Supporte à la fois une URL réseau et un asset local
/// (`assets/videos/...`) pour démarrer sans backend média.
class _InlineVideoPlayer extends StatefulWidget {
  final String url;

  const _InlineVideoPlayer({required this.url});

  @override
  State<_InlineVideoPlayer> createState() => _InlineVideoPlayerState();
}

class _InlineVideoPlayerState extends State<_InlineVideoPlayer> {
  VideoPlayerController? _controller;
  bool _erreur = false;

  @override
  void initState() {
    super.initState();
    _initialiser();
  }

  Future<void> _initialiser() async {
    try {
      final controller = widget.url.startsWith('http')
          ? VideoPlayerController.networkUrl(Uri.parse(widget.url))
          : VideoPlayerController.asset(widget.url);
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (_) {
      if (mounted) setState(() => _erreur = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_erreur) {
      return Container(
        height: 180,
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(AppRadius.md)),
        alignment: Alignment.center,
        child: const Icon(Icons.videocam_off_outlined, color: AppColors.textDisabled),
      );
    }
    final controller = _controller;
    if (controller == null) {
      return Container(
        height: 180,
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(AppRadius.md)),
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      );
    }
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.md)),
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio == 0 ? 16 / 9 : controller.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(controller),
            IconButton(
              iconSize: 48,
              color: Colors.white,
              icon: Icon(controller.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill),
              onPressed: () => setState(() {
                controller.value.isPlaying ? controller.pause() : controller.play();
              }),
            ),
          ],
        ),
      ),
    );
  }
}
