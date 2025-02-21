import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import '../models/favorite_item.dart';
import '../controllers/favorites_controller.dart';
import '../../../l10n/translations.dart';

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
    final screenWidth = MediaQuery.of(context).size.width;
    final contentWidth = screenWidth - 64; // Account for all paddings

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: contentWidth,
                      child: GptMarkdown(
                        favorite.content,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    if (favorite.reasoningContent != null &&
                        favorite.reasoningContent!.trim().isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: contentWidth,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              theme.colorScheme.surfaceVariant.withOpacity(0.5),
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
          ],
        ),
      ),
    );
  }
}
