import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../dashboard/presentation/widgets/dashboard_widgets.dart';
import '../../../dashboard/presentation/widgets/patient_dashboard_header.dart';
import '../../domain/entities/dossier_entities.dart';
import '../providers/dossier_providers.dart';
import '../widgets/evolution_chart.dart';
import '../widgets/rapport_detail_sheet.dart';

const _mois = [
  'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
  'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
];

String _dateCourte(DateTime date) => '${date.day} ${_mois[date.month - 1]}';
String _heureCourte(DateTime date) => '${date.hour.toString().padLeft(2, '0')}h${date.minute.toString().padLeft(2, '0')}';

/// Onglet 3 — Dossier (section 7.1 README) : dossier médical complet.
class DossierPage extends ConsumerWidget {
  const DossierPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const PatientDashboardHeader.page(title: 'Dossier médical', subtitle: 'Fiche patient et suivi'),
          const Divider(height: 1),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(resumePatientProvider);
                ref.invalidate(traitementsProvider);
                ref.invalidate(rapportsJournaliersProvider);
                ref.invalidate(appreciationsProvider);
                ref.invalidate(documentsMedicauxProvider);
                ref.invalidate(rendezVousProvider);
              },
              child: ListView(
                padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                children: const [
                  SectionTitle(titre: 'Fiche patient'),
                  _ResumePatientSection(),
                  SectionTitle(titre: 'Évolution des constantes (analyse IA)'),
                  _EvolutionSection(),
                  SectionTitle(titre: 'Traitement en cours'),
                  _TraitementsSection(),
                  _RapportsSectionTitle(),
                  _RapportsSection(),
                  _DocumentsSectionTitle(),
                  _DocumentsSection(),
                  _RendezVousSectionTitle(),
                  _RendezVousSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResumePatientSection extends ConsumerWidget {
  const _ResumePatientSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resumeAsync = ref.watch(resumePatientProvider);
    return resumeAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: LinearProgressIndicator(),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Text(e is AppException ? e.message : 'Erreur de chargement'),
      ),
      data: (patient) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 6),
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
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primarySurface,
                    child: Text(
                      patient.prenom.isEmpty ? '?' : patient.prenom[0].toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(patient.nomComplet, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16)),
                        Text(
                          [
                            if (patient.age != null) '${patient.age} ans',
                            if (patient.ficheNumero != null) 'Fiche ${patient.ficheNumero}',
                          ].join(' · '),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (patient.antecedents.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Text('Antécédents', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Wrap(spacing: 6, runSpacing: 6, children: [for (final a in patient.antecedents) _Tag(a, AppColors.info)]),
              ],
              if (patient.allergies.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Text('Allergies', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Wrap(spacing: 6, runSpacing: 6, children: [for (final a in patient.allergies) _Tag(a, AppColors.error)]),
              ],
              if (patient.difficultesMobilite.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Text('Difficultés de mobilité', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Wrap(spacing: 6, runSpacing: 6, children: [for (final a in patient.difficultesMobilite) _Tag(a, AppColors.warning)]),
              ],
              if (patient.contactUrgence?.nom != null) ...[
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    const Icon(Icons.emergency_outlined, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Contact urgence : ${patient.contactUrgence!.nom} (${patient.contactUrgence!.lien ?? '—'})',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color couleur;

  const _Tag(this.label, this.couleur);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: couleur.withOpacity(0.1), borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Text(label, style: TextStyle(fontSize: 11, color: couleur, fontWeight: FontWeight.w600)),
    );
  }
}

class _EvolutionSection extends ConsumerWidget {
  const _EvolutionSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rapportsAsync = ref.watch(rapportsJournaliersProvider);
    return rapportsAsync.when(
      loading: () => const SizedBox(height: 56),
      error: (_, __) => const SizedBox.shrink(),
      data: (rapports) {
        final ordonnes = [...rapports]..sort((a, b) => a.date.compareTo(b.date));
        final pouls = <double>[];
        for (final r in ordonnes) {
          for (final v in r.parametresVitaux) {
            final valeur = double.tryParse((v.pouls ?? '').replaceAll(RegExp('[^0-9.]'), ''));
            if (valeur != null) pouls.add(valeur);
          }
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 6),
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
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, size: 16, color: AppColors.secondaryDark),
                    const SizedBox(width: 6),
                    Text('Pouls (bpm) — ${pouls.length} derniers relevés', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                EvolutionSparkline(valeurs: pouls),
                const SizedBox(height: 6),
                Text(
                  'Analyse générée automatiquement à partir des rapports journaliers de l\'AVS — '
                  'ne remplace pas un avis médical.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textDisabled, fontSize: 11),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TraitementsSection extends ConsumerWidget {
  const _TraitementsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final traitementsAsync = ref.watch(traitementsProvider);
    return traitementsAsync.when(
      loading: () => const Padding(padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg), child: LinearProgressIndicator()),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Text(e is AppException ? e.message : 'Erreur de chargement'),
      ),
      data: (traitements) {
        if (traitements.isEmpty) {
          return const EmptyStateCard(icon: Icons.medication_outlined, message: 'Aucun traitement en cours enregistré.');
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            children: [
              for (final t in traitements)
                Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: AppColors.primarySurface, shape: BoxShape.circle),
                        child: const Icon(Icons.medication_outlined, color: AppColors.primaryDark, size: 18),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.dosage != null ? '${t.medicament} · ${t.dosage}' : t.medicament,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            Text(
                              [
                                if ((t.posologieMatin ?? '').isNotEmpty) 'Matin: ${t.posologieMatin}',
                                if ((t.posologieMidi ?? '').isNotEmpty) 'Midi: ${t.posologieMidi}',
                                if ((t.posologieSoir ?? '').isNotEmpty) 'Soir: ${t.posologieSoir}',
                              ].join('  ·  '),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _RapportsSectionTitle extends StatelessWidget {
  const _RapportsSectionTitle();

  @override
  Widget build(BuildContext context) => const SectionTitle(titre: 'Rapports journaliers de l\'AVS');
}

class _RapportsSection extends ConsumerWidget {
  const _RapportsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rapportsAsync = ref.watch(rapportsJournaliersProvider);
    final appreciationsAsync = ref.watch(appreciationsProvider);

    return rapportsAsync.when(
      loading: () => const Padding(padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg), child: LinearProgressIndicator()),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Text(e is AppException ? e.message : 'Erreur de chargement'),
      ),
      data: (rapports) {
        if (rapports.isEmpty) {
          return const EmptyStateCard(
            icon: Icons.medical_information_outlined,
            message: "Aucun rapport pour l'instant. Il apparaîtra ici dès la première visite de l'AVS.",
          );
        }
        final appreciations = appreciationsAsync.maybeWhen(data: (d) => d, orElse: () => const <Appreciation>[]);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            children: [
              for (final rapport in rapports)
                _RapportTile(
                  rapport: rapport,
                  appreciation: appreciations.where((a) => a.rapportId == rapport.id).firstOrNull,
                ),
            ],
          ),
        );
      },
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class _RapportTile extends StatelessWidget {
  final RapportJournalier rapport;
  final Appreciation? appreciation;

  const _RapportTile({required this.rapport, required this.appreciation});

  @override
  Widget build(BuildContext context) {
    final enRetard = rapport.statutRemise == StatutRemiseRapport.enRetard;
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
                    Row(
                      children: [
                        StatusChip(
                          label: rapport.valide ? 'Validé' : 'En attente',
                          couleur: rapport.valide ? AppColors.success : AppColors.warning,
                        ),
                        const SizedBox(width: 6),
                        if (enRetard) const StatusChip(label: 'Remis en retard', couleur: AppColors.error),
                        if (appreciation != null) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.star_rounded, size: 16, color: AppColors.secondary),
                          Text('${appreciation!.note}', style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textDisabled),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocumentsSectionTitle extends StatelessWidget {
  const _DocumentsSectionTitle();

  @override
  Widget build(BuildContext context) {
    return SectionTitle(
      titre: 'Documents médicaux',
      trailing: TextButton(onPressed: () => context.push('/documents'), child: const Text('Tout voir')),
    );
  }
}

class _DocumentsSection extends ConsumerWidget {
  const _DocumentsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(documentsMedicauxProvider);
    return docsAsync.when(
      loading: () => const Padding(padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg), child: LinearProgressIndicator()),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Text(e is AppException ? e.message : 'Erreur de chargement'),
      ),
      data: (docs) {
        if (docs.isEmpty) {
          return const EmptyStateCard(icon: Icons.folder_shared_outlined, message: 'Aucun document médical pour le moment.');
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(children: [for (final d in docs.take(3)) _DocumentTile(document: d)]),
        );
      },
    );
  }
}

class _DocumentTile extends StatelessWidget {
  final DocumentMedicalDossier document;

  const _DocumentTile({required this.document});

  IconData get _icon => switch (document.type) {
        'ordonnance' => Icons.receipt_long_outlined,
        'analyse' => Icons.science_outlined,
        _ => Icons.description_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(_icon, color: AppColors.primaryDark, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(document.nomFichier ?? 'Document', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 14)),
                Text(_dateCourte(document.dateAjout), style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RendezVousSectionTitle extends StatelessWidget {
  const _RendezVousSectionTitle();

  @override
  Widget build(BuildContext context) => const SectionTitle(titre: 'Calendrier des rendez-vous');
}

class _RendezVousSection extends ConsumerWidget {
  const _RendezVousSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rdvAsync = ref.watch(rendezVousProvider);
    return rdvAsync.when(
      loading: () => const Padding(padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg), child: LinearProgressIndicator()),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Text(e is AppException ? e.message : 'Erreur de chargement'),
      ),
      data: (rdvs) {
        if (rdvs.isEmpty) {
          return const EmptyStateCard(icon: Icons.event_available_outlined, message: 'Aucun rendez-vous planifié pour le moment.');
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(children: [for (final rdv in rdvs) _RendezVousTile(rdv: rdv)]),
        );
      },
    );
  }
}

class _RendezVousTile extends StatelessWidget {
  final RendezVousDossier rdv;

  const _RendezVousTile({required this.rdv});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: (rdv.estAVenir ? AppColors.info : AppColors.textDisabled).withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Column(
              children: [
                Text('${rdv.date.day}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: rdv.estAVenir ? AppColors.info : AppColors.textSecondary)),
                Text(_mois[rdv.date.month - 1], style: TextStyle(fontSize: 11, color: rdv.estAVenir ? AppColors.info : AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rdv.motif?.isNotEmpty == true ? rdv.motif! : (rdv.medecinNom != null ? 'Consultation avec ${rdv.medecinNom}' : 'Rendez-vous'),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                Text('${_heureCourte(rdv.date)}${rdv.lieu != null ? ' · ${rdv.lieu}' : ''}', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          StatusChip(
            label: rdv.estAVenir ? 'À venir' : 'Passé',
            couleur: rdv.estAVenir ? AppColors.info : AppColors.textDisabled,
          ),
        ],
      ),
    );
  }
}
