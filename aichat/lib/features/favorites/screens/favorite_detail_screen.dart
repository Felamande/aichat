import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import '../models/favorite_item.dart';
import '../controllers/favorites_controller.dart';
import '../../../l10n/translations.dart';
import '../../chat/widgets/message_bubble.dart';
import '../../../core/models/message.dart';

class FavoriteDetailScreen extends ConsumerWidget {
  final FavoriteItem favorite;
  final AppLocalizations l10n;

  const FavoriteDetailScreen({
    super.key,
    required this.favorite,
    required this.l10n,
  });

  void _showEditTitleDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController(text: favorite.title);
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.get('edit_title')),
        content: TextField(
          controller: titleController,
          decoration: InputDecoration(
            hintText: l10n.get('enter_title'),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.get('cancel')),
          ),
          TextButton(
            onPressed: () async {
              if (titleController.text.trim().isNotEmpty) {
                final updatedFavorite = FavoriteItem(
                  id: favorite.id,
                  title: titleController.text.trim(),
                  content: favorite.content,
                  reasoningContent: favorite.reasoningContent,
                  timestamp: favorite.timestamp,
                  isChat: favorite.isChat,
                  chatId: favorite.chatId,
                  messages: favorite.messages,
                );
                await ref
                    .read(favoritesControllerProvider.notifier)
                    .updateFavorite(updatedFavorite);
                if (context.mounted) {
                  Navigator.pop(context);
                  Navigator.pop(context); // Return to favorites list
                }
              }
            },
            child: Text(l10n.get('save')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => _showEditTitleDialog(context, ref),
          child: Row(
            children: [
              Expanded(child: Text(favorite.title)),
              Icon(
                Icons.edit,
                size: 16,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ],
          ),
        ),
      ),
      body: favorite.messages.isEmpty
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GptMarkdown(
                        favorite.content,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      if (favorite.reasoningContent != null &&
                          favorite.reasoningContent!.trim().isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceVariant
                                .withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.get('reasoning'),
                                style: theme.textTheme.titleSmall,
                              ),
                              const SizedBox(height: 8),
                              GptMarkdown(
                                favorite.reasoningContent!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            )
          : FavoriteMessageList(
              messages: favorite.messages,
              l10n: l10n,
            ),
    );
  }
}

class FavoriteMessageList extends StatelessWidget {
  final List<Message> messages;
  final AppLocalizations l10n;

  const FavoriteMessageList({
    super.key,
    required this.messages,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return MessageBubble(
          message: message,
          l10n: l10n,
          isFavorite: true,
          onCopy: (content) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.get('message_copied')),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        );
      },
    );
  }
}
