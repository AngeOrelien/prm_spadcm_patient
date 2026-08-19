import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../dashboard/presentation/widgets/dashboard_widgets.dart';
import '../../domain/entities/dossier_entities.dart';
import '../providers/dossier_providers.dart';
import '../widgets/rapport_detail_sheet.dart';

const _mois = [
  'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
  'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
];

String _dateCourte(DateTime date) => '${date.day} ${_mois[date.month - 1]}';

/// Page dédiée UC7 "Noter les tâches quotidiennes réalisées par l'AVS".
///
/// Complète (sans le remplacer) le formulaire de notation déjà présent dans
/// [showRapportDetailSheet] : cette page donne une vue d'ensemble (note
/// moyenne, visites encore à noter) et délègue la notation elle-même au
/// même bottom sheet pour ne pas dupliquer la logique d'envoi
/// (`notationAvsControllerProvider.noter`).
class NotationAvsPage extends ConsumerWidget {
  const NotationAvsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rapportsAsync = ref.watch(rapportsJournaliersProvider);
    final appreciationsAsync = ref.watch(appreciationsProvider);
    final resumeAsync = ref.watch(resumePatientProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text("Noter l'AVS")),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(rapportsJournaliersProvider);
          ref.invalidate(appreciationsProvider);
        },
        child: rapportsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [Text(e is AppException ? e.message : 'Impossible de charger vos rapports.')],
          ),
          data: (rapports) {
            if (rapports.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: const [
                  EmptyStateCard(
                    icon: Icons.star_outline_rounded,
                    message: "Vous pourrez noter l'AVS dès sa première visite et son premier rapport.",
                  ),
                ],
              );
            }

            final appreciations =
                appreciationsAsync.maybeWhen(data: (d) => d, orElse: () => const <Appreciation>[]);
            final parRapport = {for (final a in appreciations) a.rapportId: a};

            final ordonnes = [...rapports]..sort((a, b) => b.date.compareTo(a.date));
            final aNoter = ordonnes.where((r) => !parRapport.containsKey(r.id)).toList();
            final dejaNotes = ordonnes.where((r) => parRapport.containsKey(r.id)).toList();

            final avsNom = resumeAsync.maybeWhen(data: (p) => p.avsNom, orElse: () => null);

            return ListView(
              padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
              children: [
                _EnTeteNotation(avsNom: avsNom, appreciations: appreciations),
                if (aNoter.isNotEmpty) ...[
                  const SectionTitle(titre: 'Visites à noter'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Column(
                      children: [for (final r in aNoter) _VisiteTile(rapport: r, appreciation: null)],
                    ),
                  ),
                ],
                if (dejaNotes.isNotEmpty) ...[
                  const SectionTitle(titre: 'Vos appréciations'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Column(
                      children: [
                        for (final r in dejaNotes) _VisiteTile(rapport: r, appreciation: parRapport[r.id]),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _EnTeteNotation extends StatelessWidget {
  final String? avsNom;
  final List<Appreciation> appreciations;

  const _EnTeteNotation({required this.avsNom, required this.appreciations});

  double? get _moyenne {
    if (appreciations.isEmpty) return null;
    return appreciations.map((a) => a.note).reduce((a, b) => a + b) / appreciations.length;
  }

  @override
  Widget build(BuildContext context) {
    final moyenne = _moyenne;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primarySurface,
              child: Icon(Icons.badge_outlined, color: AppColors.primaryDark),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    avsNom != null && avsNom!.isNotEmpty ? avsNom! : 'Votre auxiliaire de vie',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  if (moyenne == null)
                    Text(
                      "Notez chaque visite pour aider l'équipe à suivre la qualité du suivi.",
                      style: Theme.of(context).textTheme.bodySmall,
                    )
                  else
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (i) => Icon(
                            i < moyenne.round() ? Icons.star_rounded : Icons.star_border_rounded,
                            color: AppColors.secondary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${moyenne.toStringAsFixed(1)}/5 · ${appreciations.length} appréciation${appreciations.length > 1 ? 's' : ''}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VisiteTile extends StatelessWidget {
  final RapportJournalier rapport;
  final Appreciation? appreciation;

  const _VisiteTile({required this.rapport, required this.appreciation});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => showRapportDetailSheet(context, rapport: rapport, appreciation: appreciation),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Visite du ${_dateCourte(rapport.date)}${rapport.avsNom != null ? ' · ${rapport.avsNom}' : ''}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    if (appreciation == null)
                      Text('Pas encore notée', style: Theme.of(context).textTheme.bodySmall)
                    else
                      Row(
                        children: [
                          ...List.generate(
                            5,
                            (i) => Icon(
                              i < appreciation!.note ? Icons.star_rounded : Icons.star_border_rounded,
                              color: AppColors.secondary,
                              size: 16,
                            ),
                          ),
                          if (appreciation!.commentaire.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                appreciation!.commentaire,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              if (appreciation == null)
                FilledButton.tonal(
                  onPressed: () => showRapportDetailSheet(context, rapport: rapport, appreciation: appreciation),
                  child: const Text('Noter'),
                )
              else
                const Icon(Icons.chevron_right, color: AppColors.textDisabled),
            ],
          ),
        ),
      ),
    );
  }
}
