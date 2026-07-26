import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../providers/auth_providers.dart';
import '../widgets/otp_code_field.dart';

/// Vérification du code OTP d'inscription (`POST /auth/verify-otp`) —
/// distincte de [OtpVerificationPage] utilisée pour la connexion, qui
/// appelle `verify-login-otp` (README frontend §5).
class InscriptionOtpPage extends ConsumerStatefulWidget {
  const InscriptionOtpPage({super.key});

  @override
  ConsumerState<InscriptionOtpPage> createState() => _InscriptionOtpPageState();
}

class _InscriptionOtpPageState extends ConsumerState<InscriptionOtpPage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verifier() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(inscriptionControllerProvider.notifier);
    final succes = await controller.verifierCode(_codeController.text.trim());

    if (!mounted) return;

    if (!succes) {
      final erreur = ref.read(inscriptionControllerProvider).errorMessage;
      context.showError(erreur ?? 'Code invalide');
      return;
    }
    // Compte confirmé et connecté : le router (redirect sur
    // `authControllerProvider`) bascule automatiquement vers `/accueil`, ou
    // vers `/souscrire/:soinId` si un soin était en attente (voir
    // `pendingSoinIdProvider`).
  }

  Future<void> _renvoyerCode() async {
    final email = ref.read(inscriptionControllerProvider).email;
    final controller = ref.read(inscriptionControllerProvider.notifier);
    final succes = await controller.renvoyerCode();
    if (!mounted) return;
    if (succes) {
      context.showInfo('Un nouveau code a été envoyé à $email');
    } else {
      final erreur = ref.read(inscriptionControllerProvider).errorMessage;
      context.showError(erreur ?? 'Impossible de renvoyer le code');
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.watch(inscriptionControllerProvider.select((s) => s.email));
    final isLoading = ref.watch(inscriptionControllerProvider.select((s) => s.isLoading));

    return Scaffold(
      appBar: AppBar(title: const Text('Confirmez votre compte')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.mark_email_read_outlined, size: 56),
                  const SizedBox(height: 16),
                  Text(
                    'Entre le code envoyé à\n$email',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  OtpCodeField(
                    controller: _codeController,
                    validator: Validators.otpCode,
                  ),
                  const SizedBox(height: 24),
                  AppPrimaryButton(
                    label: 'Confirmer',
                    isLoading: isLoading,
                    onPressed: _verifier,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: isLoading ? null : _renvoyerCode,
                    child: const Text('Renvoyer le code'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
