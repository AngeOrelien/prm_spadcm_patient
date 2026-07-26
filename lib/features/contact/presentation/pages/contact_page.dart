import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../providers/contact_providers.dart';

/// Formulaire public "Poser une question à propos de SPAD" (README frontend
/// §4), accessible sans compte depuis la vitrine. Un email OU un téléphone
/// est requis — même règle que la validation backend.
class ContactPage extends ConsumerStatefulWidget {
  const ContactPage({super.key});

  @override
  ConsumerState<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends ConsumerState<ContactPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _emailController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _sujetController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _nomController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _sujetController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  String? _validerEmailOuTelephone(String? value) {
    final emailRenseigne = _emailController.text.trim().isNotEmpty;
    final telephoneRenseigne = _telephoneController.text.trim().isNotEmpty;
    if (!emailRenseigne && !telephoneRenseigne) {
      return 'Renseignez au moins un email ou un téléphone';
    }
    return null;
  }

  Future<void> _envoyer() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(contactControllerProvider.notifier);
    final succes = await controller.envoyer(
      nom: _nomController.text,
      email: _emailController.text,
      telephone: _telephoneController.text,
      sujet: _sujetController.text,
      message: _messageController.text,
    );

    if (!mounted) return;

    if (succes) {
      context.showInfo('Message envoyé. L\'équipe SPAD Cameroun vous répondra bientôt.');
      Navigator.of(context).maybePop();
    } else {
      final erreur = ref.read(contactControllerProvider).error;
      final estLimite = erreur is AppException && erreur.isRateLimited;
      context.showError(
        estLimite
            ? 'Trop de messages envoyés, réessayez dans quelques minutes.'
            : (erreur is AppException ? erreur.message : "L'envoi a échoué, réessayez."),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(contactControllerProvider).isLoading;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Poser une question')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Une question sur le suivi SPAD ou nos services ? Écrivez-nous, sans créer de compte.',
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),

                AppTextField(
                  controller: _nomController,
                  label: 'Nom',
                  hint: 'Votre nom',
                  validator: (v) => Validators.requis(v, champ: 'Le nom'),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.md),

                AppTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'exemple@email.com (optionnel si téléphone renseigné)',
                  keyboardType: TextInputType.emailAddress,
                  validator: _validerEmailOuTelephone,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.md),

                AppTextField(
                  controller: _telephoneController,
                  label: 'Téléphone',
                  hint: '699000000 (optionnel si email renseigné)',
                  keyboardType: TextInputType.phone,
                  validator: _validerEmailOuTelephone,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.md),

                AppTextField(
                  controller: _sujetController,
                  label: 'Sujet',
                  hint: 'Ex : Question sur le suivi SPAD',
                  validator: (v) => Validators.requis(v, champ: 'Le sujet'),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.md),

                TextFormField(
                  controller: _messageController,
                  maxLines: 5,
                  validator: (v) => Validators.requis(v, champ: 'Le message'),
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    hintText: 'Votre question...',
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                AppPrimaryButton(
                  label: 'Envoyer',
                  isLoading: isLoading,
                  onPressed: _envoyer,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
