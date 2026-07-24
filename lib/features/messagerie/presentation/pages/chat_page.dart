import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/messagerie_entities.dart';
import '../providers/messagerie_providers.dart';

String _heure(DateTime date) => '${date.hour.toString().padLeft(2, '0')}h${date.minute.toString().padLeft(2, '0')}';

class ChatPage extends ConsumerStatefulWidget {
  final Conversation conversation;

  const ChatPage({super.key, required this.conversation});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Marque le fil comme lu à l'ouverture (met à jour le badge de la liste
    // et du compteur de notifications de l'Accueil).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(envoiMessageControllerProvider.notifier).marquerLue(widget.conversation.id);
    });
  }

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
          conversationId: widget.conversation.id,
          contenu: texte,
        );
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesProvider(widget.conversation.id));
    final monId = ref.watch(authControllerProvider).value?.id;
    final envoiEnCours = ref.watch(envoiMessageControllerProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(widget.conversation.titre)),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(e is AppException ? e.message : 'Erreur de chargement')),
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: Text('Aucun message pour le moment. Écrivez le premier !'),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: messages.length,
                  itemBuilder: (context, index) => _Bulle(message: messages[index], estDeMoi: messages[index].expediteurId == monId),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
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
                        hintText: 'Écrire un message...',
                        filled: true,
                        fillColor: AppColors.surface,
                        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.pill), borderSide: BorderSide(color: AppColors.border)),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton.filled(
                    onPressed: envoiEnCours ? null : _envoyer,
                    icon: const Icon(Icons.send_rounded),
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

class _Bulle extends StatelessWidget {
  final MessageConversation message;
  final bool estDeMoi;

  const _Bulle({required this.message, required this.estDeMoi});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: estDeMoi ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: estDeMoi ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppRadius.md),
            topRight: const Radius.circular(AppRadius.md),
            bottomLeft: Radius.circular(estDeMoi ? AppRadius.md : 2),
            bottomRight: Radius.circular(estDeMoi ? 2 : AppRadius.md),
          ),
          border: estDeMoi ? null : Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.contenu,
              style: TextStyle(color: estDeMoi ? Colors.white : AppColors.textPrimary, fontSize: 14),
            ),
            const SizedBox(height: 2),
            Text(
              _heure(message.dateEnvoi),
              style: TextStyle(fontSize: 10, color: estDeMoi ? Colors.white70 : AppColors.textDisabled),
            ),
          ],
        ),
      ),
    );
  }
}
