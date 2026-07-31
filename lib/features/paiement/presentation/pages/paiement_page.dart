import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../soins/domain/entities/soins_entities.dart';
import '../../../soins/presentation/providers/soins_providers.dart';
import '../../../soins/presentation/widgets/soin_card.dart';

/// Page de paiement (README : "simuler le paiement pour un début avec un
/// numéro de téléphone") — étape finale de la souscription, distincte de
/// [SouscriptionInfosPage] : crée d'abord la souscription
/// (`en_attente_paiement`), puis propose soit un paiement mobile money
/// simulé immédiat, soit "Payer plus tard" — dans les deux cas, le patient
/// peut continuer à utiliser l'app normalement (README : "s'il ne peut pas
/// encore payer, il peut passer").
class PaiementPage extends ConsumerStatefulWidget {
  final String soinId;
  final PatientInfoSouscription? patientInfo;

  const PaiementPage({super.key, required this.soinId, this.patientInfo});

  @override
  ConsumerState<PaiementPage> createState() => _PaiementPageState();
}

class _PaiementPageState extends ConsumerState<PaiementPage> {
  final _telephoneController = TextEditingController();
  String? _souscriptionId;
  bool _creationEnCours = true;
  String? _erreurCreation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _creerSouscription());
  }

  @override
  void dispose() {
    _telephoneController.dispose();
    super.dispose();
  }

  Future<void> _creerSouscription() async {
    setState(() {
      _creationEnCours = true;
      _erreurCreation = null;
    });
    final id = await ref.read(souscriptionControllerProvider.notifier).creerSouscription(
          soinId: widget.soinId,
          patientInfo: widget.patientInfo,
        );
    if (!mounted) return;
    if (id == null) {
      final erreur = ref.read(souscriptionControllerProvider).asError?.error;
      setState(() {
        _creationEnCours = false;
        _erreurCreation = erreur is AppException ? erreur.message : "Impossible de créer la souscription.";
      });
      return;
    }
    setState(() {
      _souscriptionId = id;
      _creationEnCours = false;
    });
  }

  Future<void> _payerMaintenant() async {
    if (_telephoneController.text.trim().isEmpty) {
      context.showError('Entrez le numéro utilisé pour le paiement mobile money.');
      return;
    }
    final id = _souscriptionId;
    if (id == null) return;

    final succes = await ref.read(souscriptionControllerProvider.notifier).payer(
          souscriptionId: id,
          numeroTelephone: _telephoneController.text.trim(),
        );
    if (!mounted) return;

    if (succes) {
      final confirmationImmediate = ref.read(souscriptionControllerProvider.notifier).derniereConfirmationImmediate;
      context.showInfo(
        confirmationImmediate
            ? 'Paiement confirmé, votre souscription est active.'
            : 'Paiement en cours de confirmation. Retrouvez le statut dans l\'onglet Soins.',
      );
      context.go('/accueil');
    } else {
      final erreur = ref.read(souscriptionControllerProvider).asError?.error;
      context.showError(erreur is AppException ? erreur.message : 'Le paiement a échoué, réessayez.');
    }
  }

  void _payerPlusTard() {
    context.showInfo(
      "Souscription enregistrée. Vous pourrez payer à tout moment depuis l'onglet Soins.",
    );
    context.go('/accueil');
  }

  @override
  Widget build(BuildContext context) {
    final soinAsync = ref.watch(soinProvider(widget.soinId));
    final isPaying = ref.watch(souscriptionControllerProvider).isLoading && !_creationEnCours;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Paiement')),
      body: SafeArea(
        child: _creationEnCours
            ? const Center(child: CircularProgressIndicator())
            : _erreurCreation != null
                ? _ErreurCreation(message: _erreurCreation!, onReessayer: _creerSouscription)
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        soinAsync.when(
                          loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
                          error: (_, __) => const SizedBox.shrink(),
                          data: (soin) => SoinCard(soin: soin, estActif: false),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, color: AppColors.primaryDark, size: 20),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  'Souscription enregistrée. Réglez maintenant par mobile money, ou payez plus tard sans perdre votre place.',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.primaryDark),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text('Numéro mobile money', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: AppSpacing.sm),
                        AppTextField(
                          controller: _telephoneController,
                          hint: '6XX XXX XXX',
                          keyboardType: TextInputType.phone,
                          prefixIcon: Icons.phone_android_outlined,
                          textInputAction: TextInputAction.done,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Paiement simulé pendant la phase de test — aucun débit réel.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        AppPrimaryButton(
                          label: 'Payer maintenant',
                          isLoading: isPaying,
                          onPressed: isPaying ? null : _payerMaintenant,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton(
                            onPressed: isPaying ? null : _payerPlusTard,
                            child: const Text('Payer plus tard'),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}

class _ErreurCreation extends StatelessWidget {
  final String message;
  final VoidCallback onReessayer;

  const _ErreurCreation({required this.message, required this.onReessayer});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: AppSpacing.md),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            FilledButton(onPressed: onReessayer, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}
