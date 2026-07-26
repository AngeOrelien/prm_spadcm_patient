import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../../../../shared/widgets/media/app_video_player.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/soins_entities.dart';
import '../providers/soins_providers.dart';
import '../widgets/soin_card.dart';

/// Écran de détail d'un soin — utilisé aussi bien depuis la vitrine publique
/// (`/soins-public/:id`, visiteur non connecté) que depuis l'onglet Soins
/// authentifié (`/soins/:id`). Le contenu (image, galerie, vidéos,
/// description) est identique ; seul le bouton du bas change de
/// comportement selon l'état de connexion et de souscription (README
/// frontend §6.2).
class SoinDetailPage extends ConsumerWidget {
  final String soinId;

  const SoinDetailPage({super.key, required this.soinId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogueAsync = ref.watch(catalogueSoinsProvider);
    // Le catalogue est déjà chargé la plupart du temps (on vient d'une
    // liste) : on cherche d'abord dedans pour éviter un aller-retour réseau
    // supplémentaire, et on retombe sur `GET /soins/:id` sinon (lien direct).
    final soinDansCatalogue = catalogueAsync.maybeWhen(
      data: (soins) {
        for (final s in soins) {
          if (s.id == soinId) return s;
        }
        return null;
      },
      orElse: () => null,
    );

    if (soinDansCatalogue != null) {
      return _SoinDetailContenu(soin: soinDansCatalogue);
    }

    final soinAsync = ref.watch(soinDetailProvider(soinId));
    return Scaffold(
      appBar: AppBar(title: const Text('Détail du service')),
      body: soinAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(e is AppException ? e.message : 'Impossible de charger ce service.'),
          ),
        ),
        data: (soin) => _SoinDetailContenu(soin: soin),
      ),
    );
  }
}

class _SoinDetailContenu extends ConsumerWidget {
  final SoinCatalogue soin;

  const _SoinDetailContenu({required this.soin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estConnecte = ref.watch(authControllerProvider).value != null;
    final souscriptionsAsync = ref.watch(souscriptionsProvider);
    final souscriptions = souscriptionsAsync.maybeWhen(data: (d) => d, orElse: () => const <Souscription>[]);

    final souscriptionBloquante = souscriptions.where((s) => s.estBloquante).toList();
    final estDejaSouscritIci = souscriptionBloquante.any((s) => s.soinId == soin.id);
    final souscritAilleurs = souscriptionBloquante.isNotEmpty && !estDejaSouscritIci;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(soin.nom)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
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
                  child: const Icon(Icons.medical_information_outlined, size: 48, color: AppColors.textDisabled),
                ),
              ),
            ),

          if (soin.images.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 100,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                scrollDirection: Axis.horizontal,
                itemCount: soin.images.length,
                separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) => ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: Image.network(
                    soin.images[index],
                    width: 140,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 140,
                      color: AppColors.surfaceMuted,
                    ),
                  ),
                ),
              ),
            ),
          ],

          if (soin.videos.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text('Vidéos', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16)),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final video in soin.videos)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: AppVideoPlayer(url: video),
                ),
              ),
          ],

          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${prixFormatte(soin.prix)} / mois',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.primaryDark),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    const Icon(Icons.event_repeat_outlined, size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(soin.frequenceVisites, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(soin.description, style: Theme.of(context).textTheme.bodyMedium),
                if (soin.prestationsIncluses.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Prestations incluses',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final prestation in soin.prestationsIncluses)
                        Chip(
                          label: Text(prestation, style: const TextStyle(fontSize: 12)),
                          backgroundColor: AppColors.surfaceMuted,
                          side: BorderSide.none,
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),

                if (estDejaSouscritIci)
                  const _MessageEtatSouscription(
                    icon: Icons.check_circle_outline,
                    couleur: AppColors.success,
                    message: 'Vous êtes déjà souscrit à ce service.',
                  )
                else if (souscritAilleurs)
                  _SouscritAilleursSection(souscription: souscriptionBloquante.first)
                else
                  AppPrimaryButton(
                    label: estConnecte ? 'Souscrire' : 'Se connecter pour souscrire',
                    onPressed: () => _souscrire(context, ref, estConnecte),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _souscrire(BuildContext context, WidgetRef ref, bool estConnecte) {
    if (!estConnecte) {
      // Mémorise le soin visé pour y revenir directement une fois
      // l'inscription/connexion terminée (voir `pendingSoinIdProvider` et
      // la redirection dans `router/app_router.dart`).
      ref.read(pendingSoinIdProvider.notifier).state = soin.id;
      context.push('/inscription');
      return;
    }
    context.push('/souscrire/${soin.id}');
  }
}

class _MessageEtatSouscription extends StatelessWidget {
  final IconData icon;
  final Color couleur;
  final String message;

  const _MessageEtatSouscription({required this.icon, required this.couleur, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: couleur.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(icon, color: couleur),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(message, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _SouscritAilleursSection extends ConsumerWidget {
  final Souscription souscription;

  const _SouscritAilleursSection({required this.souscription});

  Future<void> _terminer(BuildContext context, WidgetRef ref) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mettre fin à votre souscription'),
        content: Text(
          'Vous êtes actuellement souscrit à "${souscription.soinNom}". '
          'Y mettre fin vous permettra de souscrire à ce nouveau service. Confirmer ?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Confirmer')),
        ],
      ),
    );
    if (confirme != true || !context.mounted) return;

    final succes = await ref.read(terminerSouscriptionControllerProvider.notifier).terminer(souscription.id);
    if (!context.mounted) return;
    if (succes) {
      context.showInfo('Souscription terminée. Vous pouvez maintenant souscrire à ce service.');
    } else {
      context.showError('Impossible de terminer la souscription, réessayez.');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(terminerSouscriptionControllerProvider).isLoading;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MessageEtatSouscription(
          icon: Icons.info_outline,
          couleur: AppColors.warning,
          message:
              'Vous avez déjà une souscription en cours ("${souscription.soinNom}"). '
              'Elle doit arriver à expiration ou être terminée avant de souscrire à un autre service.',
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton(
          onPressed: isLoading ? null : () => _terminer(context, ref),
          child: isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Mettre fin à ma souscription actuelle'),
        ),
      ],
    );
  }
}
