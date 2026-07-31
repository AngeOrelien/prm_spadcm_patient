import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../alerte/presentation/providers/alerte_providers.dart';
import '../../../dashboard/domain/entities/dashboard_entities.dart';
import '../../../dashboard/presentation/widgets/dashboard_widgets.dart';
import '../../../dashboard/presentation/widgets/patient_dashboard_header.dart';
import '../../domain/entities/messagerie_entities.dart';
import '../providers/messagerie_providers.dart';
import 'chat_page.dart';

/// Onglet 4 — Messages : l'AVS affecté, l'équipe médicale/administrative
/// (médecins, coordonnateurs, administrateurs), et "Signaler une urgence" —
/// inspiré de l'espace messagerie connecté de l'AVS côté app Personnel
/// (mêmes sections par rôle, même façon d'ouvrir une conversation via
/// `POST /conversations`).
class MessageriePage extends ConsumerStatefulWidget {
  const MessageriePage({super.key});

  @override
  ConsumerState<MessageriePage> createState() => _MessageriePageState();
}

class _MessageriePageState extends ConsumerState<MessageriePage> {
  String? _idEnCoursDouverture;

  Future<void> _ouvrirConversation(String participantId) async {
    if (_idEnCoursDouverture != null) return;
    setState(() => _idEnCoursDouverture = participantId);
    try {
      final conversation = await ref.read(messagerieActionsProvider).ouvrirConversationAvec(participantId);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ChatPage(conversation: conversation)),
      );
      ref.invalidate(conversationsProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _idEnCoursDouverture = null);
    }
  }

  void _rafraichirTout() {
    ref.invalidate(conversationsProvider);
    ref.invalidate(avsAssigneMessagerieProvider);
    ref.invalidate(personnelAnnuaireProvider('medecin'));
    ref.invalidate(personnelAnnuaireProvider('coordonnateur'));
    ref.invalidate(personnelAnnuaireProvider('administrateur'));
  }

  Future<void> _signalerUrgence() async {
    final descriptionController = TextEditingController();
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _FeuilleUrgence(descriptionController: descriptionController),
    );
    descriptionController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conversationsAsync = ref.watch(conversationsProvider);
    final avsAsync = ref.watch(avsAssigneMessagerieProvider);
    final medecinsAsync = ref.watch(personnelAnnuaireProvider('medecin'));
    final coordonnateursAsync = ref.watch(personnelAnnuaireProvider('coordonnateur'));
    final adminsAsync = ref.watch(personnelAnnuaireProvider('administrateur'));
    final conversations = conversationsAsync.whenOrNull(data: (v) => v) ?? const <Conversation>[];

    String? dernierMessageAvec(String participantId) {
      for (final c in conversations) {
        if (c.interlocuteurId == participantId) return c.dernierMessage;
      }
      return null;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const PatientDashboardHeader.page(
            title: 'Messages',
            subtitle: 'Votre équipe SPAD Cameroun',
          ),
          const Divider(height: 1),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _rafraichirTout(),
              child: ListView(
                padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                children: [
                  const SizedBox(height: AppSpacing.sm),
                  _TuileUrgence(onTap: _signalerUrgence),
                  const Divider(height: AppSpacing.lg),
                  _SectionAvs(
                    async: avsAsync,
                    idEnCoursDouverture: _idEnCoursDouverture,
                    dernierMessageAvec: dernierMessageAvec,
                    onOuvrir: _ouvrirConversation,
                  ),
                  _SectionAnnuaire(
                    titre: 'Médecins',
                    async: medecinsAsync,
                    couleur: AppColors.info,
                    dernierMessageAvec: dernierMessageAvec,
                    idEnCoursDouverture: _idEnCoursDouverture,
                    onOuvrir: (p) => _ouvrirConversation(p.id),
                  ),
                  _SectionAnnuaire(
                    titre: 'Coordonnateurs',
                    async: coordonnateursAsync,
                    couleur: AppColors.secondaryDark,
                    dernierMessageAvec: dernierMessageAvec,
                    idEnCoursDouverture: _idEnCoursDouverture,
                    onOuvrir: (p) => _ouvrirConversation(p.id),
                  ),
                  _SectionAnnuaire(
                    titre: 'Administrateurs',
                    async: adminsAsync,
                    couleur: AppColors.warning,
                    dernierMessageAvec: dernierMessageAvec,
                    idEnCoursDouverture: _idEnCoursDouverture,
                    onOuvrir: (p) => _ouvrirConversation(p.id),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TuileUrgence extends StatelessWidget {
  final VoidCallback onTap;

  const _TuileUrgence({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Material(
        color: AppColors.sos.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.sos,
                  child: Icon(Icons.sos_rounded, color: Colors.white),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Signaler une urgence', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: AppColors.sos)),
                      Text(
                        "L'AVS de garde et le coordonnateur sont notifiés immédiatement",
                        maxLines: 2,
                        style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.sos),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeuilleUrgence extends ConsumerStatefulWidget {
  final TextEditingController descriptionController;

  const _FeuilleUrgence({required this.descriptionController});

  @override
  ConsumerState<_FeuilleUrgence> createState() => _FeuilleUrgenceState();
}

class _FeuilleUrgenceState extends ConsumerState<_FeuilleUrgence> {
  Future<void> _confirmer() async {
    final succes = await ref.read(declenchementAlerteControllerProvider.notifier).declencher(
          description: widget.descriptionController.text.trim().isEmpty ? null : widget.descriptionController.text.trim(),
        );
    if (!mounted) return;
    if (succes) {
      Navigator.of(context).pop(true);
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
  Widget build(BuildContext context) {
    final envoiEnCours = ref.watch(declenchementAlerteControllerProvider).isLoading;
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.sos_rounded, color: AppColors.sos, size: 28),
              const SizedBox(width: AppSpacing.sm),
              Text('Signaler une urgence', style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            "Décrivez brièvement la situation si possible. L'AVS de garde et le coordonnateur seront notifiés immédiatement.",
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: widget.descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Ex: chute, douleur soudaine, malaise...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.sos),
              onPressed: envoiEnCours ? null : _confirmer,
              child: envoiEnCours
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : const Text("Confirmer l'urgence"),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: envoiEnCours ? null : () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }
}

class _SectionAvs extends StatelessWidget {
  final AsyncValue<AvsAssigne?> async;
  final String? idEnCoursDouverture;
  final String? Function(String) dernierMessageAvec;
  final void Function(String) onOuvrir;

  const _SectionAvs({
    required this.async,
    required this.idEnCoursDouverture,
    required this.dernierMessageAvec,
    required this.onOuvrir,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(titre: 'Mon AVS'),
        async.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: LinearProgressIndicator(),
          ),
          error: (e, __) => const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text('Impossible de charger cette section.', style: TextStyle(color: AppColors.textSecondary)),
          ),
          data: (avs) {
            if (avs == null) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text("Aucun AVS n'est encore affecté à votre suivi.", style: TextStyle(color: AppColors.textSecondary)),
              );
            }
            return _TuileContact(
              nom: avs.nomComplet,
              sousTitre: dernierMessageAvec(avs.id) ?? 'Votre auxiliaire de vie sociale',
              couleur: AppColors.primary,
              chargement: idEnCoursDouverture == avs.id,
              onTap: () => onOuvrir(avs.id),
            );
          },
        ),
      ],
    );
  }
}

class _SectionAnnuaire extends StatelessWidget {
  final String titre;
  final AsyncValue<List<PersonnelAnnuaire>> async;
  final Color couleur;
  final String? Function(String) dernierMessageAvec;
  final String? idEnCoursDouverture;
  final void Function(PersonnelAnnuaire) onOuvrir;

  const _SectionAnnuaire({
    required this.titre,
    required this.async,
    required this.couleur,
    required this.dernierMessageAvec,
    required this.idEnCoursDouverture,
    required this.onOuvrir,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(titre: titre),
        async.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: LinearProgressIndicator(),
          ),
          error: (e, __) => const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text('Non disponible pour le moment.', style: TextStyle(color: AppColors.textSecondary)),
          ),
          data: (liste) => liste.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Text('Aucun contact dans cette catégorie.', style: TextStyle(color: AppColors.textSecondary)),
                )
              : Column(
                  children: [
                    for (final p in liste)
                      _TuileContact(
                        nom: p.nomComplet,
                        sousTitre: dernierMessageAvec(p.id) ?? titre.substring(0, titre.length - 1),
                        couleur: couleur,
                        chargement: idEnCoursDouverture == p.id,
                        onTap: () => onOuvrir(p),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _TuileContact extends StatelessWidget {
  final String nom;
  final String sousTitre;
  final Color couleur;
  final bool chargement;
  final VoidCallback onTap;

  const _TuileContact({
    required this.nom,
    required this.sousTitre,
    required this.couleur,
    required this.chargement,
    required this.onTap,
  });

  String get _initiales {
    final mots = nom.trim().split(RegExp(r'\s+')).where((m) => m.isNotEmpty);
    if (mots.isEmpty) return '?';
    if (mots.length == 1) return mots.first.substring(0, 1).toUpperCase();
    return (mots.first.substring(0, 1) + mots.last.substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: couleur.withOpacity(0.15),
        child: Text(_initiales, style: TextStyle(color: couleur, fontWeight: FontWeight.bold)),
      ),
      title: Text(nom, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(sousTitre, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: chargement
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.chevron_right, color: AppColors.textDisabled),
      onTap: chargement ? null : onTap,
    );
  }
}
