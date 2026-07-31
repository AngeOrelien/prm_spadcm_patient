import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../providers/dossier_providers.dart';

/// Étape 2/2 de l'onboarding "Créer mon dossier" : informations médicales.
/// Combine [donneesPersonnelles] (étape 1) avec les champs saisis ici et
/// envoie le tout en un seul `POST /api/patients/moi`.
class DossierOnboardingMedicalPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> donneesPersonnelles;
  final String? soinId;

  const DossierOnboardingMedicalPage({super.key, required this.donneesPersonnelles, this.soinId});

  @override
  ConsumerState<DossierOnboardingMedicalPage> createState() => _DossierOnboardingMedicalPageState();
}

class _DossierOnboardingMedicalPageState extends ConsumerState<DossierOnboardingMedicalPage> {
  final _pathologieController = TextEditingController();
  final _antecedentsController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _informationsSanteController = TextEditingController();
  final _regimeAlimentaireController = TextEditingController();

  @override
  void dispose() {
    _pathologieController.dispose();
    _antecedentsController.dispose();
    _allergiesController.dispose();
    _informationsSanteController.dispose();
    _regimeAlimentaireController.dispose();
    super.dispose();
  }

  List<String> _listeDepuis(String texte) =>
      texte.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  Future<void> _terminer() async {
    final donnees = <String, dynamic>{
      ...widget.donneesPersonnelles,
      if (_pathologieController.text.trim().isNotEmpty) 'pathologie': _pathologieController.text.trim(),
      if (_antecedentsController.text.trim().isNotEmpty) 'antecedents': _listeDepuis(_antecedentsController.text),
      if (_allergiesController.text.trim().isNotEmpty) 'allergies': _listeDepuis(_allergiesController.text),
      if (_informationsSanteController.text.trim().isNotEmpty)
        'informationsSante': _informationsSanteController.text.trim(),
      if (_regimeAlimentaireController.text.trim().isNotEmpty)
        'regimeAlimentaire': _regimeAlimentaireController.text.trim(),
    };

    final succes = await ref.read(creationDossierControllerProvider.notifier).creer(donnees);
    if (!mounted) return;

    if (succes) {
      final soinId = widget.soinId;
      if (soinId != null) {
        context.go('/soins/souscrire/$soinId');
      } else {
        context.go('/onboarding/souscription');
      }
    } else {
      final erreur = ref.read(creationDossierControllerProvider).asError?.error;
      context.showError(erreur is AppException ? erreur.message : 'Impossible de créer le dossier, réessaie.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isLoading = ref.watch(creationDossierControllerProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Mon dossier médical')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppRadius.pill)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppRadius.pill)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Étape 2 sur 2', style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              Text('Vos informations de santé', style: textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(
                "Ces informations aident l'équipe SPAD Cameroun à préparer un suivi adapté. Tout est facultatif et modifiable plus tard.",
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),

              Text('Pathologie / diagnostic principal', style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(controller: _pathologieController, hint: 'Ex: Diabète type 2', textInputAction: TextInputAction.next),
              const SizedBox(height: AppSpacing.md),

              Text('Antécédents médicaux', style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                controller: _antecedentsController,
                hint: 'Séparés par des virgules, ex: hypertension, AVC 2019',
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.md),

              Text('Allergies', style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                controller: _allergiesController,
                hint: 'Séparées par des virgules, ex: pénicilline, arachide',
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.md),

              Text('Informations santé complémentaires', style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                controller: _informationsSanteController,
                hint: 'Traitements en cours, mobilité, autres précisions...',
                maxLines: 3,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.md),

              Text('Régime alimentaire', style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                controller: _regimeAlimentaireController,
                hint: 'Ex: sans sel, diabétique...',
                maxLines: 2,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: AppSpacing.xl),

              AppPrimaryButton(label: 'Créer mon dossier', isLoading: isLoading, onPressed: _terminer),
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: TextButton(
                  onPressed: isLoading ? null : () => Navigator.of(context).maybePop(),
                  child: const Text('Retour'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
