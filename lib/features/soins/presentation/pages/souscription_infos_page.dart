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

/// Formulaire `patientInfo` rempli au moment de la souscription (README
/// section 0 et 7.1) : allergies, informations santé, régime alimentaire.
/// Nom/prénom pré-remplis depuis le compte connecté et modifiables, mais
/// facultatifs — le backend les reprend du compte si absents.
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
  final _informationsSanteController = TextEditingController();
  final _regimeAlimentaireController = TextEditingController();

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
    _informationsSanteController.dispose();
    _regimeAlimentaireController.dispose();
    super.dispose();
  }

  Future<void> _confirmerEtPayer() async {
    if (!_formKey.currentState!.validate()) return;

    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payer et souscrire ?'),
        content: const Text('Le paiement sera effectué via mobile money.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Payer et souscrire')),
        ],
      ),
    );
    if (confirme != true || !mounted) return;

    final allergies = _allergiesController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final patientInfo = PatientInfoSouscription(
      allergies: allergies,
      informationsSante: _informationsSanteController.text,
      regimeAlimentaire: _regimeAlimentaireController.text,
      nom: _nomController.text,
      prenom: _prenomController.text,
    );

    final controller = ref.read(souscriptionControllerProvider.notifier);
    final succes = await controller.souscrire(soinId: widget.soinId, patientInfo: patientInfo);

    if (!mounted) return;

    if (succes) {
      final confirmationImmediate = controller.derniereConfirmationImmediate;
      context.showInfo(
        confirmationImmediate
            ? 'Souscription confirmée, paiement effectué avec succès.'
            : 'Paiement en cours de confirmation. Retrouvez le statut dans l\'onglet Soins.',
      );
      // Retour à l'accueil : go_router recalculera aussi le redirect si
      // l'inscription venait juste d'avoir lieu.
      if (context.canPop()) {
        context.go('/accueil');
      } else {
        context.go('/accueil');
      }
    } else {
      final erreur = ref.read(souscriptionControllerProvider).asError?.error;
      final message = erreur is AppException ? erreur.message : 'Le paiement a échoué, réessayez.';
      context.showError(message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(souscriptionControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Vos informations santé')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Ces informations aident l'équipe SPAD Cameroun à préparer le suivi à domicile. "
                  "Le nom et le prénom sont facultatifs si votre compte est déjà complet.",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(controller: _nomController, label: 'Nom (facultatif)'),
                const SizedBox(height: AppSpacing.md),
                AppTextField(controller: _prenomController, label: 'Prénom (facultatif)'),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _allergiesController,
                  label: 'Allergies (facultatif)',
                  hint: 'Séparées par des virgules, ex: pénicilline, arachide',
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _informationsSanteController,
                  label: 'Informations santé (facultatif)',
                  hint: 'Antécédents, traitements en cours...',
                  maxLines: 3,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _regimeAlimentaireController,
                  label: 'Régime alimentaire (facultatif)',
                  hint: 'Ex: sans sel, diabétique...',
                  maxLines: 2,
                ),
                const SizedBox(height: AppSpacing.xl),
                AppPrimaryButton(
                  label: 'Payer et souscrire',
                  isLoading: isLoading,
                  onPressed: _confirmerEtPayer,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
