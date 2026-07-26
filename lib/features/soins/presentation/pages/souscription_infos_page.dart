import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/soins_entities.dart';
import '../providers/soins_providers.dart';

/// Formulaire rempli juste avant de payer (README frontend §7.1) :
/// allergies / informations santé / régime alimentaire, transmis
/// directement dans `POST /souscriptions` via `patientInfo` — pas de
/// dossier `Patient` à créer séparément au préalable.
class SouscriptionInfosPage extends ConsumerStatefulWidget {
  final String soinId;

  const SouscriptionInfosPage({super.key, required this.soinId});

  @override
  ConsumerState<SouscriptionInfosPage> createState() => _SouscriptionInfosPageState();
}

class _SouscriptionInfosPageState extends ConsumerState<SouscriptionInfosPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomController;
  late final TextEditingController _prenomController;
  final _allergiesController = TextEditingController();
  final _santeController = TextEditingController();
  final _regimeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final patient = ref.read(authControllerProvider).value;
    _nomController = TextEditingController(text: patient?.nom ?? '');
    _prenomController = TextEditingController(text: patient?.prenom ?? '');
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _allergiesController.dispose();
    _santeController.dispose();
    _regimeController.dispose();
    super.dispose();
  }

  Future<void> _confirmer() async {
    if (!_formKey.currentState!.validate()) return;

    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la souscription'),
        content: const Text(
          'Le paiement sera effectué via mobile money. Confirmer la souscription et le paiement ?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Payer et souscrire')),
        ],
      ),
    );
    if (confirme != true || !mounted) return;

    final patientInfo = PatientInfoSouscription(
      nom: _nomController.text,
      prenom: _prenomController.text,
      allergies: _allergiesController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      informationsSante: _santeController.text,
      regimeAlimentaire: _regimeController.text,
    );

    final resultat = await ref.read(souscriptionControllerProvider.notifier).souscrireEtPayer(
          soinId: widget.soinId,
          patientInfo: patientInfo,
        );

    if (!mounted) return;

    if (resultat == null) {
      final erreur = ref.read(souscriptionControllerProvider).error;
      context.showError(erreur is AppException ? erreur.message : 'Le paiement a échoué, réessayez.');
      return;
    }

    if (resultat == ResultatSouscription.confirmee) {
      context.showInfo('Souscription confirmée, paiement effectué avec succès.');
    } else {
      context.showInfo('Souscription enregistrée. Le paiement est en cours de confirmation.');
    }
    if (context.canPop()) {
      context.pop();
    }
    context.go('/soins');
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(souscriptionControllerProvider).isLoading;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Vos informations')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Ces informations aident l\'équipe SPAD Cameroun à préparer le suivi à domicile. '
                  'Vous pourrez les compléter plus tard depuis votre profil.',
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Nom', style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSpacing.sm),
                AppTextField(controller: _nomController, hint: 'Nom'),
                const SizedBox(height: AppSpacing.md),
                Text('Prénom', style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSpacing.sm),
                AppTextField(controller: _prenomController, hint: 'Prénom'),
                const SizedBox(height: AppSpacing.md),
                Text('Allergies', style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSpacing.sm),
                AppTextField(
                  controller: _allergiesController,
                  hint: 'Ex : pénicilline, arachides (séparées par des virgules)',
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Informations santé', style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _santeController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Ex : mobilité réduite, utilise un déambulateur',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Régime alimentaire', style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _regimeController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Ex : sans sel, pas de produits laitiers',
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                AppPrimaryButton(
                  label: 'Continuer vers le paiement',
                  isLoading: isLoading,
                  onPressed: _confirmer,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
