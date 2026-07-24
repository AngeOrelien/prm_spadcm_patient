import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/messagerie_entities.dart';
import '../providers/messagerie_providers.dart';
import 'chat_page.dart';

/// Onglet 4 — Messages (section 7.1 README) : deux fils de discussion,
/// un avec l'administration, un avec l'AVS assigné.
class MessageriePage extends ConsumerWidget {
  const MessageriePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Messages')),
      body: conversationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(e is AppException ? e.message : 'Une erreur est survenue.'),
          ),
        ),
        data: (conversations) => ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: conversations.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) => _ConversationCard(conversation: conversations[index]),
        ),
      ),
    );
  }
}

class _ConversationCard extends ConsumerWidget {
  final Conversation conversation;

  const _ConversationCard({required this.conversation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(messagesProvider(conversation.id));
    final monId = ref.watch(authControllerProvider).value?.id;
    final estAvs = conversation.type == TypeConversation.avs;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ChatPage(conversation: conversation)),
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.border)),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: estAvs ? AppColors.secondarySurface : AppColors.primarySurface,
                child: Icon(
                  estAvs ? Icons.volunteer_activism_outlined : Icons.support_agent_outlined,
                  color: estAvs ? AppColors.secondaryDark : AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(conversation.titre, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 2),
                    messagesAsync.when(
                      loading: () => Text('...', style: Theme.of(context).textTheme.bodySmall),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (messages) => Text(
                        messages.isEmpty ? 'Aucun message pour le moment' : messages.last.contenu,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              messagesAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (messages) {
                  final nonLus = messages.where((m) => !m.lu && m.expediteurId != monId).length;
                  if (nonLus == 0) return const Icon(Icons.chevron_right, color: AppColors.textDisabled);
                  return CircleAvatar(
                    radius: 10,
                    backgroundColor: AppColors.secondary,
                    child: Text('$nonLus', style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
