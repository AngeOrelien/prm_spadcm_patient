import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../../../../shared/widgets/buttons/app_social_button.dart';
import '../../../../shared/widgets/inputs/app_checkbox_tile.dart';
import '../../../../shared/widgets/inputs/app_password_field.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/misc/app_circle_icon_button.dart';
import '../../../../shared/widgets/misc/app_or_divider.dart';
import '../providers/auth_providers.dart';
import 'otp_verification_page.dart';

/// Écran de connexion de l'app Patients/Familles. Flux en 2 étapes :
///   1. Email + mot de passe -> vérifiés côté serveur.
///   2. Code OTP envoyé par email -> [OtpVerificationPage].
///
/// Pas d'inscription libre ici pour l'instant : le compte est provisionné
/// au dossier du patient par SPAD Cameroun (cf. feuille de route, section
/// "Prochaines étapes" du README).
class LoginEmailPage extends ConsumerStatefulWidget {
  const LoginEmailPage({super.key});

  @override
  ConsumerState<LoginEmailPage> createState() => _LoginEmailPageState();
}

class _LoginEmailPageState extends ConsumerState<LoginEmailPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _seSouvenirDeMoi = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _soumettre() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(otpLoginControllerProvider.notifier);
    final succes = await controller.demanderCode(
      email: _emailController.text.trim(),
      motDePasse: _passwordController.text,
    );

    if (!mounted) return;

    if (succes) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const OtpVerificationPage()),
      );
    } else {
      final erreur = ref.read(otpLoginControllerProvider).errorMessage;
      context.showError(erreur ?? 'Email ou mot de passe incorrect');
    }
  }

  void _motDePasseOublie() {
    context.showInfo(
      "Réinitialisation à venir. En attendant, contacte l'équipe SPAD Cameroun.",
    );
  }

  void _continuerAvecGoogle() {
    context.showInfo('Connexion avec Google bientôt disponible.');
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(otpLoginControllerProvider.select((s) => s.isLoading));
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
                // --- Barre du haut : retour + titre centré ---
                Row(
                  children: [
                    AppCircleIconButton(
                      icon: Icons.arrow_back_ios_new,
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    Expanded(
                      child: Text('Connexion', style: textTheme.titleLarge, textAlign: TextAlign.center),
                    ),
                    const SizedBox(width: 40), // équilibre visuel avec le bouton retour
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                // --- Logo de l'app ---
                Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: 100,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.favorite_outline,
                      size: 64,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                Text('Content de vous revoir', style: textTheme.headlineMedium, textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Connectez-vous pour suivre l\'état de santé de votre proche',
                  style: textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),

                // --- Email ---
                Text('Email', style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSpacing.sm),
                AppTextField(
                  controller: _emailController,
                  hint: 'exemple@email.com',
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                  prefixIcon: Icons.person_outline,
                  textInputAction: TextInputAction.next,
                  autofocus: true,
                ),
                const SizedBox(height: AppSpacing.lg),

                // --- Mot de passe ---
                Text('Mot de passe', style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSpacing.sm),
                AppPasswordField(
                  controller: _passwordController,
                  hint: 'Entrez votre mot de passe',
                  validator: Validators.password,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: AppSpacing.sm),

                // --- Se souvenir de moi / mot de passe oublié ---
                Row(
                  children: [
                    AppCheckboxTile(
                      value: _seSouvenirDeMoi,
                      onChanged: (v) => setState(() => _seSouvenirDeMoi = v),
                      label: 'Se souvenir de moi',
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: isLoading ? null : _motDePasseOublie,
                      child: const Text('Mot de passe oublié ?'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                AppPrimaryButton(
                  label: 'Connexion',
                  isLoading: isLoading,
                  onPressed: _soumettre,
                ),
                const SizedBox(height: AppSpacing.lg),

                const AppOrDivider(),
                const SizedBox(height: AppSpacing.lg),

                AppSocialButton(
                  label: 'Continuer avec Google',
                  icon: Image.asset(
                    'assets/images/google_logo.png',
                    height: 22,
                    width: 22,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.g_mobiledata, size: 26),
                  ),
                  onPressed: isLoading ? null : _continuerAvecGoogle,
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
