import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_dimens.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../paiement/presentation/pages/paiement_page.dart';
import '../../domain/entities/soins_entities.dart';

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

  void _continuerVersPaiement() {
    if (!_formKey.currentState!.validate()) return;

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

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaiementPage(soinId: widget.soinId, patientInfo: patientInfo),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  label: 'Continuer vers le paiement',
                  onPressed: _continuerVersPaiement,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
