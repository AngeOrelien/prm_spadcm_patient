import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import 'dossier_onboarding_medical_page.dart';

/// Étape 1/2 de l'onboarding "Créer mon dossier" (juste après l'inscription,
/// avant tout accès au reste de l'app — voir `app_router.dart`) :
/// informations personnelles/administratives.
///
/// N'appelle aucune route backend elle-même : les données saisies ici sont
/// transmises à [DossierOnboardingMedicalPage], qui les combine avec les
/// informations médicales et envoie le tout en un seul
/// `POST /api/patients/moi` à la toute fin du parcours.
class DossierOnboardingPersonnelPage extends ConsumerStatefulWidget {
  final String? soinId;

  const DossierOnboardingPersonnelPage({super.key, this.soinId});

  @override
  ConsumerState<DossierOnboardingPersonnelPage> createState() => _DossierOnboardingPersonnelPageState();
}

class _DossierOnboardingPersonnelPageState extends ConsumerState<DossierOnboardingPersonnelPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _telephoneController;
  final _villeController = TextEditingController();
  final _quartierController = TextEditingController();
  final _adresseController = TextEditingController();
  final _contactNomController = TextEditingController();
  final _contactLienController = TextEditingController();
  final _contactTelephoneController = TextEditingController();
  DateTime? _dateNaissance;
  String? _genre;

  @override
  void initState() {
    super.initState();
    _telephoneController = TextEditingController();
  }

  @override
  void dispose() {
    _telephoneController.dispose();
    _villeController.dispose();
    _quartierController.dispose();
    _adresseController.dispose();
    _contactNomController.dispose();
    _contactLienController.dispose();
    _contactTelephoneController.dispose();
    super.dispose();
  }

  Future<void> _choisirDateNaissance() async {
    final maintenant = DateTime.now();
    final choisie = await showDatePicker(
      context: context,
      initialDate: DateTime(maintenant.year - 60),
      firstDate: DateTime(maintenant.year - 120),
      lastDate: maintenant,
      helpText: 'Date de naissance',
    );
    if (choisie != null) setState(() => _dateNaissance = choisie);
  }

  void _continuer() {
    if (!_formKey.currentState!.validate()) return;

    final donneesPersonnelles = <String, dynamic>{
      if (_dateNaissance != null) 'dateNaissance': _dateNaissance!.toIso8601String(),
      if (_genre != null) 'genre': _genre,
      if (_telephoneController.text.trim().isNotEmpty) 'telephone': _telephoneController.text.trim(),
      if (_villeController.text.trim().isNotEmpty) 'ville': _villeController.text.trim(),
      if (_quartierController.text.trim().isNotEmpty) 'quartier': _quartierController.text.trim(),
      if (_adresseController.text.trim().isNotEmpty) 'adresse': _adresseController.text.trim(),
      if (_contactNomController.text.trim().isNotEmpty ||
          _contactLienController.text.trim().isNotEmpty ||
          _contactTelephoneController.text.trim().isNotEmpty)
        'contactUrgence': {
          if (_contactNomController.text.trim().isNotEmpty) 'nom': _contactNomController.text.trim(),
          if (_contactLienController.text.trim().isNotEmpty) 'lien': _contactLienController.text.trim(),
          if (_contactTelephoneController.text.trim().isNotEmpty) 'telephone': _contactTelephoneController.text.trim(),
        },
    };

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DossierOnboardingMedicalPage(donneesPersonnelles: donneesPersonnelles, soinId: widget.soinId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mon dossier personnel'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _EnTeteEtape(
                  etape: 1,
                  total: 2,
                  titre: 'Vos informations personnelles',
                  description:
                      "Ces informations administratives permettent à l'équipe SPAD Cameroun de créer votre dossier patient. Tout est modifiable plus tard depuis votre profil.",
                ),
                const SizedBox(height: AppSpacing.lg),

                Text('Date de naissance', style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSpacing.sm),
                InkWell(
                  onTap: _choisirDateNaissance,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: InputDecorator(
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.cake_outlined)),
                    child: Text(
                      _dateNaissance == null
                          ? 'Sélectionner une date'
                          : '${_dateNaissance!.day.toString().padLeft(2, '0')}/${_dateNaissance!.month.toString().padLeft(2, '0')}/${_dateNaissance!.year}',
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                Text('Genre', style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSpacing.sm),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'homme', label: Text('Homme')),
                    ButtonSegment(value: 'femme', label: Text('Femme')),
                  ],
                  selected: _genre == null ? const {} : {_genre!},
                  emptySelectionAllowed: true,
                  onSelectionChanged: (s) => setState(() => _genre = s.isEmpty ? null : s.first),
                ),
                const SizedBox(height: AppSpacing.md),

                Text('Téléphone', style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSpacing.sm),
                AppTextField(
                  controller: _telephoneController,
                  hint: '6XX XXX XXX',
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.md),

                Text('Ville', style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSpacing.sm),
                AppTextField(
                  controller: _villeController,
                  hint: 'Ex: Yaoundé',
                  prefixIcon: Icons.location_city_outlined,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.md),

                Text('Quartier', style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSpacing.sm),
                AppTextField(
                  controller: _quartierController,
                  hint: 'Ex: Bastos',
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.md),

                Text('Adresse complète', style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSpacing.sm),
                AppTextField(
                  controller: _adresseController,
                  hint: 'Repères, rue, numéro de porte...',
                  maxLines: 2,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.lg),

                Text('Contact d\'urgence (facultatif)', style: textTheme.titleLarge?.copyWith(fontSize: 15)),
                const SizedBox(height: AppSpacing.sm),
                AppTextField(controller: _contactNomController, hint: 'Nom du contact', textInputAction: TextInputAction.next),
                const SizedBox(height: AppSpacing.md),
                AppTextField(controller: _contactLienController, hint: 'Lien (ex: Fils, Épouse)', textInputAction: TextInputAction.next),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _contactTelephoneController,
                  hint: 'Téléphone du contact',
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: AppSpacing.xl),

                AppPrimaryButton(label: 'Continuer', onPressed: _continuer),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EnTeteEtape extends StatelessWidget {
  final int etape;
  final int total;
  final String titre;
  final String description;

  const _EnTeteEtape({required this.etape, required this.total, required this.titre, required this.description});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 1; i <= total; i++) ...[
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: i <= etape ? AppColors.primary : AppColors.border,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              if (i != total) const SizedBox(width: 6),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Étape $etape sur $total', style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text(titre, style: textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(description, style: textTheme.bodyMedium),
      ],
    );
  }
}
