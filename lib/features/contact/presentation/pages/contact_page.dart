import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../providers/contact_providers.dart';

/// Formulaire de contact public de la vitrine (README section 4). Affiché
/// soit en route dédiée (`/contact`), soit via [showContactSheet] en
/// bottom sheet directement depuis `/vitrine` — plus léger si on ne veut
/// pas d'une route à part.
class ContactPage extends ConsumerStatefulWidget {
  const ContactPage({super.key});

  @override
  ConsumerState<ContactPage> createState() => _ContactPageState();
}

Future<void> showContactSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => const Padding(
      padding: EdgeInsets.only(top: AppSpacing.md),
      child: ContactPage(),
    ),
  );
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

  String? _emailOuTelephoneValidator(String? value) {
    final autreRenseigne = _emailController.text.trim().isNotEmpty || _telephoneController.text.trim().isNotEmpty;
    if (!autreRenseigne) {
      return 'Renseigne au moins un email ou un téléphone';
    }
    return null;
  }

  Future<void> _envoyer() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(contactControllerProvider.notifier);
    final succes = await controller.envoyer(
      nom: _nomController.text.trim(),
      email: _emailController.text,
      telephone: _telephoneController.text,
      sujet: _sujetController.text.trim(),
      message: _messageController.text.trim(),
    );

    if (!mounted) return;

    if (succes) {
      context.showInfo('Votre message a été envoyé, merci !');
      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
    } else {
      final erreur = ref.read(contactControllerProvider).asError?.error;
      final message = erreur is AppException
          ? (erreur.isRateLimited
              ? 'Trop de messages envoyés, réessaie dans quelques minutes.'
              : erreur.message)
          : 'Impossible d\'envoyer le message, réessaie.';
      context.showError(message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(contactControllerProvider).isLoading;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(4)),
              ),
            ),
            Text('Une question ?', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(
              "L'équipe SPAD Cameroun vous répond rapidement.",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _nomController,
              label: 'Nom',
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Le nom est requis' : null,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _emailController,
              label: 'Email (facultatif si téléphone renseigné)',
              keyboardType: TextInputType.emailAddress,
              validator: (v) => (v != null && v.trim().isNotEmpty) ? Validators.email(v) : _emailOuTelephoneValidator(v),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _telephoneController,
              label: 'Téléphone (facultatif si email renseigné)',
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _sujetController,
              label: 'Sujet',
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Le sujet est requis' : null,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _messageController,
              label: 'Message',
              maxLines: 4,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Le message est requis' : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppPrimaryButton(label: 'Envoyer', isLoading: isLoading, onPressed: _envoyer),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}
