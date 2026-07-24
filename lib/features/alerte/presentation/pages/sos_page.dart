import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../providers/alerte_providers.dart';

/// Déclenchement d'une alerte SOS (UC4 "Déclencher alerte SOS").
///
/// Ouverte en plein écran (pas nichée dans un onglet) via le bouton flottant
/// toujours visible du shell, pour rester atteignable en un geste depuis
/// n'importe quel onglet. Tant que le vrai service de notifications FCM
/// n'est pas branché (Phase 3), l'alerte est créée côté mock et apparaît
/// immédiatement dans le badge "alertes ouvertes" de l'Accueil.
class SosPage extends ConsumerWidget {
  const SosPage({super.key});

  Future<void> _confirmer(BuildContext context, WidgetRef ref) async {
    final succes = await ref.read(declenchementAlerteControllerProvider.notifier).declencher();
    if (!context.mounted) return;
    if (succes) {
      Navigator.of(context).maybePop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Alerte envoyée : l'AVS de garde et le coordonnateur ont été notifiés.")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("L'envoi de l'alerte a échoué, réessayez.")),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final envoiEnCours = ref.watch(declenchementAlerteControllerProvider).isLoading;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.sos,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
              const Spacer(),
              const Icon(Icons.sos_rounded, size: 96, color: Colors.white),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Déclencher une alerte SOS',
                style: textTheme.headlineMedium?.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                "L'équipe SPAD Cameroun (AVS de garde et coordonnateur) sera "
                'notifiée immédiatement.',
                style: textTheme.bodyLarge?.copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.sos,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                  onPressed: envoiEnCours ? null : () => _confirmer(context, ref),
                  child: envoiEnCours
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.sos),
                        )
                      : const Text(
                          'Confirmer l\'alerte',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () => Navigator.of(context).maybePop(),
                style: TextButton.styleFrom(foregroundColor: Colors.white70),
                child: const Text('Annuler'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
