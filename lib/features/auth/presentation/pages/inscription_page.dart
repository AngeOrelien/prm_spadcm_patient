import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// Écran d'inscription libre (vitrine publique, README frontend §5) :
/// nom, prénom, email, téléphone, mot de passe -> `POST /auth/register`,
/// puis code OTP de confirmation sur [InscriptionOtpPage].
class InscriptionPage extends ConsumerStatefulWidget {
  const InscriptionPage({super.key});

  @override
  ConsumerState<InscriptionPage> createState() => _InscriptionPageState();
}

class _InscriptionPageState extends ConsumerState<InscriptionPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _motDePasseController = TextEditingController();
  final _confirmationController = TextEditingController();

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _motDePasseController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  String? _validerConfirmation(String? value) {
    if (value != _motDePasseController.text) {
      return 'Les mots de passe ne correspondent pas';
    }
    return null;
  }

  Future<void> _soumettre() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(inscriptionControllerProvider.notifier);
    final succes = await controller.inscrire(
      nom: _nomController.text,
      prenom: _prenomController.text,
      email: _emailController.text.trim(),
      telephone: _telephoneController.text,
      motDePasse: _motDePasseController.text,
    );

    if (!mounted) return;

    if (succes) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const InscriptionOtpPage()),
      );
    } else {
      final erreur = ref.read(inscriptionControllerProvider).errorMessage;
      context.showError(erreur ?? "L'inscription a échoué, réessayez.");
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
                  'Créez votre compte patient pour souscrire à un service de suivi SPAD Cameroun',
                  style: textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),

                Text('Nom', style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSpacing.sm),
                AppTextField(
                  controller: _nomController,
                  hint: 'Votre nom',
                  validator: (v) => Validators.requis(v, champ: 'Le nom'),
                  textInputAction: TextInputAction.next,
                  autofocus: true,
                ),
                const SizedBox(height: AppSpacing.md),

                Text('Prénom', style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSpacing.sm),
                AppTextField(
                  controller: _prenomController,
                  hint: 'Votre prénom',
                  validator: (v) => Validators.requis(v, champ: 'Le prénom'),
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
                  prefixIcon: Icons.mail_outline,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.md),

                Text('Téléphone', style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSpacing.sm),
                AppTextField(
                  controller: _telephoneController,
                  hint: '+237 6XX XXX XXX',
                  keyboardType: TextInputType.phone,
                  validator: Validators.telephone,
                  prefixIcon: Icons.phone_outlined,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.md),

                Text('Mot de passe', style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSpacing.sm),
                AppPasswordField(
                  controller: _motDePasseController,
                  hint: 'Au moins 8 caractères',
                  validator: Validators.password,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.md),

                Text('Confirmer le mot de passe', style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSpacing.sm),
                AppPasswordField(
                  controller: _confirmationController,
                  hint: 'Retapez votre mot de passe',
                  validator: _validerConfirmation,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: AppSpacing.xl),

                AppPrimaryButton(
                  label: 'Créer mon compte',
                  isLoading: isLoading,
                  onPressed: _soumettre,
                ),
                const SizedBox(height: AppSpacing.md),

                Center(
                  child: TextButton(
                    onPressed: isLoading ? null : () => Navigator.of(context).maybePop(),
                    child: const Text.rich(
                      TextSpan(
                        text: 'Déjà un compte ? ',
                        children: [
                          TextSpan(
                            text: 'Se connecter',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
