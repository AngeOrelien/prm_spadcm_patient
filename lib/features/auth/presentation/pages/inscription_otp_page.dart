import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../providers/auth_providers.dart';
import '../widgets/otp_code_field.dart';

/// Vérification du code OTP d'inscription (README section 5), branchée sur
/// `InscriptionController.verifierCode` — distincte de
/// `OtpVerificationPage` utilisée pour la connexion.
///
/// Si [soinId] est renseigné (inscription déclenchée depuis un tap
/// "Souscrire" sur `/soins-public/:id`), redirige directement vers le
/// formulaire de souscription de ce soin une fois le compte vérifié,
/// plutôt que vers l'accueil.
class InscriptionOtpPage extends ConsumerStatefulWidget {
  final String? soinId;

  const InscriptionOtpPage({super.key, this.soinId});

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

    // Le compte est désormais connecté (authControllerProvider mis à jour) :
    // on revient directement au parcours de souscription si un soin était
    // visé, sinon le router redirige naturellement vers /accueil.
    final soinId = widget.soinId;
    if (soinId != null) {
      context.go('/soins/souscrire/$soinId');
    }
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
      appBar: AppBar(title: const Text('Vérification')),
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
                    label: 'Vérifier',
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
