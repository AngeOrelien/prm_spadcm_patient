import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../auth/domain/entities/patient.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Une icône d'action à droite du header (notifications, ajout...). Chaque
/// page choisit ses propres actions, comme côté app Personnel.
class HeaderAction {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool badge;

  const HeaderAction({
    required this.icon,
    required this.tooltip,
    this.onTap,
    this.badge = false,
  });
}

/// En-tête réutilisable de l'app Patients/Familles, calqué sur
/// `AppDashboardHeader` de l'app Personnel pour garder une identité visuelle
/// commune aux deux apps (même dégradé teal, même bouton "⋮").
///
/// Deux modes :
///  - [PatientDashboardHeader.greeting] -> mode "accueil" : avatar (initiales)
///    + "Bonjour, Nom" + rôle (Patient/Famille). Tape sur l'avatar -> profil.
///  - [PatientDashboardHeader.page] -> mode "page" : simple titre (+
///    sous-titre optionnel), pour les autres onglets (Soins, Rendez-vous...).
class PatientDashboardHeader extends ConsumerWidget {
  final bool showGreeting;
  final String? title;
  final String? subtitle;
  final List<HeaderAction> actions;

  const PatientDashboardHeader.greeting({
    super.key,
    this.actions = const [],
  })  : showGreeting = true,
        title = null,
        subtitle = null;

  const PatientDashboardHeader.page({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
  })  : showGreeting = false;

  String _initiales(String nomComplet) {
    final mots = nomComplet.trim().split(RegExp(r'\s+')).where((m) => m.isNotEmpty);
    if (mots.isEmpty) return '?';
    if (mots.length == 1) return mots.first.substring(0, 1).toUpperCase();
    return (mots.first.substring(0, 1) + mots.last.substring(0, 1)).toUpperCase();
  }

  String _libelleRole(RoleCompteMenager role) {
    return role == RoleCompteMenager.patient ? 'Patient' : 'Proche aidant';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final patient = ref.watch(authControllerProvider).value;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.md, AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: showGreeting ? _buildGreeting(context, textTheme, patient) : _buildTitle(textTheme),
              ),
              for (final action in actions) ...[
                const SizedBox(width: AppSpacing.xs),
                _HeaderIconButton(
                  icon: action.icon,
                  tooltip: action.tooltip,
                  avecPastille: action.badge,
                  onTap: action.onTap,
                ),
              ],
              const SizedBox(width: AppSpacing.xs),
              _OverflowMenuButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreeting(BuildContext context, TextTheme textTheme, Patient? patient) {
    final nomComplet = patient?.nomComplet ?? '';
    return InkWell(
      onTap: () => context.go('/profil'),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white.withOpacity(0.18),
            child: Text(
              _initiales(nomComplet),
              style: textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 16),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Bonjour, ${patient?.prenom ?? ''}',
                  style: textTheme.titleLarge?.copyWith(fontSize: 16, color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  patient != null ? _libelleRole(patient.role) : '',
                  style: textTheme.bodySmall?.copyWith(color: Colors.white.withOpacity(0.85)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title ?? '',
          style: textTheme.titleLarge?.copyWith(fontSize: 20, color: Colors.white),
          overflow: TextOverflow.ellipsis,
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            style: textTheme.bodySmall?.copyWith(color: Colors.white.withOpacity(0.85)),
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool avecPastille;
  final VoidCallback? onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    this.avecPastille = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.16),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, size: 22, color: Colors.white),
              if (avecPastille)
                Positioned(
                  right: -1,
                  top: -1,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bouton "⋮" façon WhatsApp : "Mon profil" et "Déconnexion" restent
/// accessibles depuis n'importe quel onglet sans consommer d'espace dans la
/// bottom navigation.
class _OverflowMenuButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.white.withOpacity(0.16),
      shape: const CircleBorder(),
      child: PopupMenuButton<String>(
        tooltip: "Plus d'options",
        icon: const Icon(Icons.more_vert, color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        onSelected: (valeur) => _onSelected(context, ref, valeur),
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'profil',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.person_outline, color: AppColors.textPrimary),
              title: Text('Mon profil'),
            ),
          ),
          const PopupMenuItem(
            value: 'deconnexion',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.logout, color: AppColors.error),
              title: Text('Déconnexion', style: TextStyle(color: AppColors.error)),
            ),
          ),
        ],
      ),
    );
  }

  void _onSelected(BuildContext context, WidgetRef ref, String valeur) {
    switch (valeur) {
      case 'profil':
        context.go('/profil');
        break;
      case 'deconnexion':
        _confirmerDeconnexion(context, ref);
        break;
    }
  }

  void _confirmerDeconnexion(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Se déconnecter ?'),
          content: const Text('Vous devrez vous reconnecter pour accéder à nouveau à l\'app.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Annuler')),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                ref.read(authControllerProvider.notifier).deconnecter();
              },
              child: const Text('Déconnexion'),
            ),
          ],
        );
      },
    );
  }
}
