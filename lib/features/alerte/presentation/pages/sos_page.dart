import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';

/// Déclenchement d'une alerte SOS (UC4 "Déclencher alerte SOS").
///
/// Ouverte en plein écran (pas nichée dans un onglet) via le bouton flottant
/// toujours visible du shell, pour rester atteignable en un geste depuis
/// n'importe quel onglet. La logique d'envoi réelle (création d'une
/// `Alerte` + notification push FCM au coordonnateur/AVS de garde, cf.
/// section 3 du README — relation `<<include>>` vers le service de
/// notifications) sera branchée en Phase 3.
class SosPage extends StatelessWidget {
  const SosPage({super.key});

  @override
  Widget build(BuildContext context) {
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
                  onPressed: () {
                    // TODO(Phase 3): POST /api/alertes + notification FCM.
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Envoi de l\'alerte bientôt disponible.')),
                    );
                  },
                  child: const Text(
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
