import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../../../../shared/widgets/inputs/app_password_field.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/misc/app_circle_icon_button.dart';
import '../providers/auth_providers.dart';
import 'inscription_otp_page.dart';

/// Formulaire d'inscription libre (README section 5) : nom, prénom, email,
/// téléphone, mot de passe + confirmation. Garde en mémoire le `soinId`
/// visé (si on vient d'un tap "Souscrire" sur `/soins-public/:id`) pour
/// revenir directement au formulaire de souscription une fois connecté.
class InscriptionPage extends ConsumerStatefulWidget {
  final String? soinId;

  const InscriptionPage({super.key, this.soinId});

  @override
  ConsumerState<InscriptionPage> createState() => _InscriptionPageState();
}

class _InscriptionPageState extends ConsumerState<InscriptionPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _confirmationMotDePasse(String? value) {
    if (value != _passwordController.text) {
      return 'Les mots de passe ne correspondent pas';
    }
    return null;
  }

  String? _telephoneValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le téléphone est requis';
    }
    return null;
  }

  Future<void> _soumettre() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(inscriptionControllerProvider.notifier);
    final succes = await controller.inscrire(
      nom: _nomController.text,
      prenom: _prenomController.text,
      email: _emailController.text,
      telephone: _telephoneController.text,
      motDePasse: _passwordController.text,
    );

    if (!mounted) return;

    if (succes) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => InscriptionOtpPage(soinId: widget.soinId)),
      );
    } else {
      final erreur = ref.read(inscriptionControllerProvider).errorMessage;
      context.showError(erreur ?? "Impossible de créer le compte, réessaie.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(inscriptionControllerProvider.select((s) => s.isLoading));
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    AppCircleIconButton(
                      icon: Icons.arrow_back_ios_new,
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    Expanded(
                      child: Text('Créer un compte', style: textTheme.titleLarge, textAlign: TextAlign.center),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Créez votre compte pour souscrire à un forfait SPAD Cameroun',
                  style: textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),

                Text('Nom', style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSpacing.sm),
                AppTextField(
                  controller: _nomController,
                  hint: 'Votre nom',
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Le nom est requis' : null,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.md),

                Text('Prénom', style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSpacing.sm),
                AppTextField(
                  controller: _prenomController,
                  hint: 'Votre prénom',
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Le prénom est requis' : null,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.md),

                Text('Email', style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSpacing.sm),
                AppTextField(
                  controller: _emailController,
                  hint: 'exemple@email.com',
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                  prefixIcon: Icons.email_outlined,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.md),

                Text('Téléphone', style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSpacing.sm),
                AppTextField(
                  controller: _telephoneController,
                  hint: '6XX XXX XXX',
                  keyboardType: TextInputType.phone,
                  validator: _telephoneValidator,
                  prefixIcon: Icons.phone_outlined,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.md),

                Text('Mot de passe', style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSpacing.sm),
                AppPasswordField(
                  controller: _passwordController,
                  hint: 'Créez un mot de passe',
                  validator: Validators.password,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.md),

                Text('Confirmer le mot de passe', style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSpacing.sm),
                AppPasswordField(
                  controller: _confirmPasswordController,
                  hint: 'Ressaisissez le mot de passe',
                  validator: _confirmationMotDePasse,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: AppSpacing.lg),

                AppPrimaryButton(
                  label: 'Créer mon compte',
                  isLoading: isLoading,
                  onPressed: _soumettre,
                ),
                const SizedBox(height: AppSpacing.md),

                Center(
                  child: TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('J\'ai déjà un compte ? Se connecter'),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
      backgroundColor: AppColors.background,
    );
  }
}
