import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/messagerie_entities.dart';
import '../providers/messagerie_providers.dart';

String _heure(DateTime date) => '${date.hour.toString().padLeft(2, '0')}h${date.minute.toString().padLeft(2, '0')}';

/// Détail d'un fil de discussion (Administration ou AVS assigné). Poussé
/// hors bottom navigation (voir `app_router.dart`) pour occuper tout
/// l'écran, comme n'importe quelle app de messagerie.
class ConversationPage extends ConsumerStatefulWidget {
  final String conversationId;
  final String titre;

  const ConversationPage({super.key, required this.conversationId, required this.titre});

  @override
  ConsumerState<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends ConsumerState<ConversationPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    final texte = _controller.text;
    if (texte.trim().isEmpty) return;
    _controller.clear();
    await ref.read(envoiMessageControllerProvider.notifier).envoyer(
          conversationId: widget.conversationId,
          contenu: texte,
        );
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesProvider(widget.conversationId));
    final envoiEnCours = ref.watch(envoiMessageControllerProvider).isLoading;
    final monId = ref.watch(authControllerProvider).maybeWhen(data: (p) => p?.id, orElse: () => null) ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(widget.titre)),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text(error is AppException ? error.message : 'Une erreur est survenue.'),
              ),
              data: (messages) => ListView.builder(
                reverse: false,
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: messages.length,
                itemBuilder: (context, index) => _MessageBubble(message: messages[index], monId: monId),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.xs, AppSpacing.sm, AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _envoyer(),
                      decoration: InputDecoration(
                        hintText: 'Écrire un message…',
                        filled: true,
                        fillColor: AppColors.surface,
                        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  IconButton.filled(
                    onPressed: envoiEnCours ? null : _envoyer,
                    icon: envoiEnCours
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded),
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

class _MessageBubble extends StatelessWidget {
  final MessageConversation message;
  final String monId;

  const _MessageBubble({required this.message, required this.monId});

  @override
  Widget build(BuildContext context) {
    final bool moi = message.estDeMoi(monId);
    final String contenu = message.contenu;
    final DateTime dateEnvoi = message.dateEnvoi;

    return Align(
      alignment: moi ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 8),
        decoration: BoxDecoration(
          color: moi ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppRadius.md),
            topRight: const Radius.circular(AppRadius.md),
            bottomLeft: Radius.circular(moi ? AppRadius.md : 2),
            bottomRight: Radius.circular(moi ? 2 : AppRadius.md),
          ),
          border: moi ? null : Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(contenu, style: TextStyle(color: moi ? Colors.white : AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(
              _heure(dateEnvoi),
              style: TextStyle(fontSize: 10, color: moi ? Colors.white70 : AppColors.textDisabled),
            ),
          ],
        ),
      ),
    );
  }
}
