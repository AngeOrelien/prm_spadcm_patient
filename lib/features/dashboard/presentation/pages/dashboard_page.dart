import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../domain/entities/dashboard_entities.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/dashboard_widgets.dart';
import '../widgets/patient_dashboard_header.dart';

const _mois = [
  'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
  'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
];

String _dateCourte(DateTime date) => '${date.day} ${_mois[date.month - 1]}';

String _heureCourte(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}h${date.minute.toString().padLeft(2, '0')}';

/// Onglet 1 — Tableau de bord santé (UC2 "Consulter tableau de bord santé").
/// Point d'entrée vers : constantes récentes, dernier rapport AVS, résumé
/// IA, traitements en cours, prochain rendez-vous, alertes en cours et accès
/// rapide aux documents médicaux (UC5). Entièrement branché sur
/// `GET /api/patients/moi/dashboard` (voir `dashboard_providers.dart`).
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tableauAsync = ref.watch(tableauDeBordProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          PatientDashboardHeader.greeting(
            actions: [
              HeaderAction(
                icon: Icons.notifications_outlined,
                tooltip: 'Notifications',
                badge: tableauAsync.whenOrNull(data: (t) => t.notificationsNonLues > 0) ?? false,
                onTap: () => context.showInfo('Notifications bientôt disponibles.'),
              ),
            ],
          ),
          const Divider(height: 1),
          Expanded(
            child: tableauAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _ErreurTableauDeBord(
                message: error is AppException ? error.message : 'Une erreur est survenue.',
                onReessayer: () => ref.invalidate(tableauDeBordProvider),
              ),
              data: (tableau) => RefreshIndicator(
                onRefresh: () async => ref.invalidate(tableauDeBordProvider),
                child: _TableauDeBordContenu(tableau: tableau),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErreurTableauDeBord extends StatelessWidget {
  final String message;
  final VoidCallback onReessayer;

  const _ErreurTableauDeBord({required this.message, required this.onReessayer});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 40, color: AppColors.textDisabled),
            const SizedBox(height: AppSpacing.md),
            Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: onReessayer,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TableauDeBordContenu extends StatelessWidget {
  final TableauDeBord tableau;

  const _TableauDeBordContenu({required this.tableau});

  @override
  Widget build(BuildContext context) {
    final patient = tableau.patient;

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      children: [
        // --- Ligne de statistiques rapides ---
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: 1.3,
            children: [
              StatCard(
                valeur: '${tableau.traitementsActifs.length}',
                libelle: 'Traitements en cours',
                icon: Icons.medication_outlined,
                couleur: AppColors.primary,
                onTap: () => context.go('/dossier'),
              ),
              StatCard(
                valeur: tableau.prochainRendezVous != null
                    ? _dateCourte(tableau.prochainRendezVous!.date)
                    : '—',
                libelle: 'Prochain rendez-vous',
                icon: Icons.event_outlined,
                couleur: AppColors.info,
                onTap: () => context.go('/dossier'),
              ),
              StatCard(
                valeur: '${tableau.alertesOuvertes.length}',
                libelle: tableau.alertesOuvertes.isEmpty ? 'Aucune alerte en cours' : 'Alerte(s) en cours',
                icon: Icons.warning_amber_outlined,
                couleur: tableau.alertesOuvertes.isEmpty ? AppColors.success : AppColors.sos,
                onTap: () => context.go('/messages'),
              ),
              StatCard(
                valeur: '${tableau.documentsRecents.length}',
                libelle: 'Documents médicaux',
                icon: Icons.folder_shared_outlined,
                couleur: AppColors.secondary,
                onTap: () => context.push('/documents'),
              ),
            ],
          ),
        ),

        // --- Alertes en cours (mise en avant si présentes) ---
        if (tableau.alertesOuvertes.isNotEmpty) ...[
          SectionTitle(titre: 'Alertes en cours'),
          for (final alerte in tableau.alertesOuvertes) _AlerteCard(alerte: alerte),
        ],

        // --- Dernières constantes / dernier rapport de soins ---
        SectionTitle(
          titre: 'Dernières constantes',
          trailing: TextButton(
            onPressed: () => context.go('/dossier'),
            child: const Text('Tout voir'),
          ),
        ),
        if (tableau.dernierRapport == null)
          const EmptyStateCard(
            icon: Icons.favorite_outline,
            message:
                "Aucun rapport de soins validé pour l'instant. Il apparaîtra ici dès que "
                "l'AVS aura effectué une visite.",
          )
        else
          _DernierRapportCard(rapport: tableau.dernierRapport!),

        // --- Traitement en cours ---
        SectionTitle(titre: 'Traitement en cours'),
        if (tableau.traitementsActifs.isEmpty)
          const EmptyStateCard(
            icon: Icons.medication_outlined,
            message: 'Aucun traitement en cours enregistré.',
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              children: [
                for (final traitement in tableau.traitementsActifs) _TraitementTile(traitement: traitement),
              ],
            ),
          ),

        // --- Prochain rendez-vous ---
        SectionTitle(
          titre: 'Prochain rendez-vous',
          trailing: TextButton(
            onPressed: () => context.go('/dossier'),
            child: const Text('Calendrier'),
          ),
        ),
        if (tableau.prochainRendezVous == null)
          const EmptyStateCard(
            icon: Icons.event_available_outlined,
            message: 'Aucun rendez-vous planifié pour le moment.',
          )
        else
          _RendezVousCard(rdv: tableau.prochainRendezVous!),

        // --- Équipe soignante ---
        SectionTitle(titre: 'Équipe soignante'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            children: [
              if (patient.medecinReferentNom != null)
                _PersonneTile(
                  icon: Icons.medical_services_outlined,
                  nom: 'Dr ${patient.medecinReferentNom}',
                  sousTitre: patient.medecinReferentSpecialite ?? 'Médecin référent',
                  telephone: patient.medecinReferentTelephone,
                ),
              if (tableau.avsAssigne != null)
                _PersonneTile(
                  icon: Icons.volunteer_activism_outlined,
                  nom: tableau.avsAssigne!.nomComplet,
                  sousTitre: tableau.avsAssigne!.zoneAffectation ?? 'Auxiliaire de vie sociale',
                  telephone: tableau.avsAssigne!.telephone,
                ),
              if (patient.medecinReferentNom == null && tableau.avsAssigne == null)
                const EmptyStateCard(
                  icon: Icons.groups_outlined,
                  message: "Aucun membre de l'équipe soignante assigné pour l'instant.",
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AlerteCard extends StatelessWidget {
  final AlerteOuverte alerte;

  const _AlerteCard({required this.alerte});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.sos.withOpacity(0.06),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.sos.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            const Icon(Icons.sos_rounded, color: AppColors.sos),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alerte.description?.isNotEmpty == true ? alerte.description! : 'Alerte SOS',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  Text(
                    'Déclenchée le ${_dateCourte(alerte.dateCreation)} à ${_heureCourte(alerte.dateCreation)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            StatusChip(label: alerte.statut.libelle, couleur: alerte.statut.couleur),
          ],
        ),
      ),
    );
  }
}

class _DernierRapportCard extends StatelessWidget {
  final DernierRapport rapport;

  const _DernierRapportCard({required this.rapport});

  @override
  Widget build(BuildContext context) {
    final releve = rapport.dernierReleve;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 6),
      child: Container(
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
                Expanded(
                  child: Text(
                    'Visite du ${_dateCourte(rapport.date)}'
                    '${rapport.avsNom != null ? ' · ${rapport.avsNom}' : ''}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
                StatusChip(
                  label: rapport.valide ? 'Validé' : 'En attente',
                  couleur: rapport.valide ? AppColors.success : AppColors.warning,
                ),
              ],
            ),
            if (releve != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  ConstanteChip(icon: Icons.favorite_outline, libelle: 'Pouls', valeur: releve.pouls),
                  ConstanteChip(
                    icon: Icons.monitor_heart_outlined,
                    libelle: 'Tension',
                    valeur: releve.taBrasDroit ?? releve.taBrasGauche,
                  ),
                  ConstanteChip(icon: Icons.thermostat_outlined, libelle: 'Température', valeur: releve.temperature),
                  ConstanteChip(icon: Icons.air_outlined, libelle: 'SpO2', valeur: releve.spo2),
                  ConstanteChip(icon: Icons.water_drop_outlined, libelle: 'Glycémie', valeur: releve.glycemie),
                ],
              ),
            ],
            if (rapport.resumeIA != null && rapport.resumeIA!.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.secondarySurface,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.auto_awesome, size: 16, color: AppColors.secondaryDark),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        rapport.resumeIA!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (rapport.observations != null && rapport.observations!.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                rapport.observations!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TraitementTile extends StatelessWidget {
  final TraitementActif traitement;

  const _TraitementTile({required this.traitement});

  String get _posologie {
    final parts = <String>[];
    if (traitement.posologieMatin?.isNotEmpty == true) parts.add('M: ${traitement.posologieMatin}');
    if (traitement.posologieMidi?.isNotEmpty == true) parts.add('Mi: ${traitement.posologieMidi}');
    if (traitement.posologieSoir?.isNotEmpty == true) parts.add('S: ${traitement.posologieSoir}');
    return parts.isEmpty ? 'Posologie non précisée' : parts.join('  ·  ');
  }

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
                  traitement.dosage != null ? '${traitement.medicament} · ${traitement.dosage}' : traitement.medicament,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                Text(_posologie, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RendezVousCard extends StatelessWidget {
  final ProchainRendezVous rdv;

  const _RendezVousCard({required this.rdv});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 6),
      child: Container(
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
                color: AppColors.info.withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Column(
                children: [
                  Text('${rdv.date.day}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.info)),
                  Text(_mois[rdv.date.month - 1], style: const TextStyle(fontSize: 11, color: AppColors.info)),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rdv.motif?.isNotEmpty == true
                        ? rdv.motif!
                        : (rdv.medecinNom != null ? 'Consultation avec ${rdv.medecinNom}' : 'Rendez-vous'),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  Text(
                    '${_heureCourte(rdv.date)}${rdv.lieu != null ? ' · ${rdv.lieu}' : ''}',
                    style: Theme.of(context).textTheme.bodySmall,
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

class _PersonneTile extends StatelessWidget {
  final IconData icon;
  final String nom;
  final String sousTitre;
  final String? telephone;

  const _PersonneTile({required this.icon, required this.nom, required this.sousTitre, this.telephone});

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
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withOpacity(0.12),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nom, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(sousTitre, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          if (telephone != null && telephone!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.call_outlined, color: AppColors.primary),
              tooltip: 'Appeler',
              onPressed: () {},
            ),
        ],
      ),
    );
  }
}
