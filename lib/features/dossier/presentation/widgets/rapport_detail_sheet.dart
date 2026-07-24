import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../dashboard/presentation/widgets/dashboard_widgets.dart';
import '../../domain/entities/dossier_entities.dart';
import '../providers/dossier_providers.dart';

const _mois = [
  'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
  'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
];

String _dateLongue(DateTime date) => '${date.day} ${_mois[date.month - 1]} ${date.year}';

Future<void> showRapportDetailSheet(
  BuildContext context, {
  required RapportJournalier rapport,
  Appreciation? appreciation,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => _RapportDetailContent(
        rapport: rapport,
        appreciation: appreciation,
        scrollController: scrollController,
      ),
    ),
  );
}

class _RapportDetailContent extends StatelessWidget {
  final RapportJournalier rapport;
  final Appreciation? appreciation;
  final ScrollController scrollController;

  const _RapportDetailContent({required this.rapport, required this.appreciation, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(AppRadius.pill)),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: Text('Visite du ${_dateLongue(rapport.date)}', style: textTheme.titleLarge?.copyWith(fontSize: 17)),
            ),
            StatusChip(
              label: rapport.valide ? 'Validé' : 'En attente',
              couleur: rapport.valide ? AppColors.success : AppColors.warning,
            ),
          ],
        ),
        if (rapport.avsNom != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text('Par ${rapport.avsNom}', style: textTheme.bodySmall),
          ),
        const SizedBox(height: AppSpacing.md),

        if (rapport.resumeIA != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.secondarySurface,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.auto_awesome, size: 18, color: AppColors.secondaryDark),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(rapport.resumeIA!, style: textTheme.bodySmall)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        Text('Constantes', style: textTheme.titleLarge?.copyWith(fontSize: 15)),
        const SizedBox(height: AppSpacing.sm),
        for (final v in rapport.parametresVitaux) _ConstantesRow(vitaux: v),

        const SizedBox(height: AppSpacing.md),
        Text('Soins & tâches', style: textTheme.titleLarge?.copyWith(fontSize: 15)),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [for (final t in rapport.soinsTaches) _Puce(label: t)],
        ),

        if (rapport.activites.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text('Activités', style: textTheme.titleLarge?.copyWith(fontSize: 15)),
          const SizedBox(height: AppSpacing.sm),
          Wrap(spacing: 6, runSpacing: 6, children: [for (final a in rapport.activites) _Puce(label: a)]),
        ],

        if (rapport.medicamentsAdministres.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text('Médicaments administrés', style: textTheme.titleLarge?.copyWith(fontSize: 15)),
          const SizedBox(height: AppSpacing.sm),
          for (final m in rapport.medicamentsAdministres)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: Icon(
                m.pris ? Icons.check_circle : Icons.cancel_outlined,
                color: m.pris ? AppColors.success : AppColors.error,
                size: 20,
              ),
              title: Text('${m.nom} · ${m.posologiePrise ?? ''}', style: const TextStyle(fontSize: 14)),
              subtitle: Text(m.moment, style: textTheme.bodySmall),
            ),
        ],

        if (rapport.observations != null && rapport.observations!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text('Observations', style: textTheme.titleLarge?.copyWith(fontSize: 15)),
          const SizedBox(height: AppSpacing.sm),
          Text(rapport.observations!, style: textTheme.bodyMedium),
        ],

        if (rapport.plainte != null && rapport.plainte!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text('Plainte signalée', style: textTheme.titleLarge?.copyWith(fontSize: 15, color: AppColors.error)),
          const SizedBox(height: AppSpacing.sm),
          Text(rapport.plainte!, style: textTheme.bodyMedium),
        ],

        const SizedBox(height: AppSpacing.lg),
        const Divider(),
        const SizedBox(height: AppSpacing.sm),
        Text('Votre appréciation', style: textTheme.titleLarge?.copyWith(fontSize: 15)),
        const SizedBox(height: AppSpacing.sm),
        _NotationSection(rapport: rapport, appreciation: appreciation),
      ],
    );
  }
}

class _ConstantesRow extends StatelessWidget {
  final ParametresVitauxDossier vitaux;

  const _ConstantesRow({required this.vitaux});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            vitaux.moment[0].toUpperCase() + vitaux.moment.substring(1),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              ConstanteChip(icon: Icons.favorite_outline, libelle: 'Pouls', valeur: vitaux.pouls),
              ConstanteChip(icon: Icons.monitor_heart_outlined, libelle: 'Tension', valeur: vitaux.taBrasDroit ?? vitaux.taBrasGauche),
              ConstanteChip(icon: Icons.thermostat_outlined, libelle: 'Température', valeur: vitaux.temperature),
              ConstanteChip(icon: Icons.air_outlined, libelle: 'SpO2', valeur: vitaux.spo2),
              ConstanteChip(icon: Icons.water_drop_outlined, libelle: 'Glycémie', valeur: vitaux.glycemie),
            ],
          ),
        ],
      ),
    );
  }
}

class _Puce extends StatelessWidget {
  final String label;

  const _Puce({required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: AppColors.surfaceMuted,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _NotationSection extends ConsumerStatefulWidget {
  final RapportJournalier rapport;
  final Appreciation? appreciation;

  const _NotationSection({required this.rapport, required this.appreciation});

  @override
  ConsumerState<_NotationSection> createState() => _NotationSectionState();
}

class _NotationSectionState extends ConsumerState<_NotationSection> {
  late int _note = widget.appreciation?.note ?? 5;
  late final _commentaireController = TextEditingController(text: widget.appreciation?.commentaire ?? '');

  @override
  void dispose() {
    _commentaireController.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    final succes = await ref.read(notationAvsControllerProvider.notifier).noter(
          rapportId: widget.rapport.id,
          note: _note,
          commentaire: _commentaireController.text.trim(),
        );
    if (!mounted) return;
    if (succes) {
      context.showInfo('Merci pour votre appréciation !');
      Navigator.of(context).maybePop();
    } else {
      context.showError("L'envoi a échoué, réessayez.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(notationAvsControllerProvider).isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 1; i <= 5; i++)
              IconButton(
                onPressed: () => setState(() => _note = i),
                icon: Icon(
                  i <= _note ? Icons.star_rounded : Icons.star_border_rounded,
                  color: AppColors.secondary,
                  size: 28,
                ),
              ),
          ],
        ),
        TextField(
          controller: _commentaireController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: "Un commentaire sur la visite de l'AVS (optionnel)",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: isLoading ? null : _envoyer,
            child: Text(widget.appreciation == null ? 'Envoyer mon appréciation' : 'Mettre à jour'),
          ),
        ),
      ],
    );
  }
}
