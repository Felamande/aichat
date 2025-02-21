import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import '../models/favorite_item.dart';
import '../../../l10n/translations.dart';

class FavoriteDetailScreen extends StatelessWidget {
  final FavoriteItem favorite;
  final AppLocalizations l10n;

  const FavoriteDetailScreen({
    super.key,
    required this.favorite,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final contentWidth = screenWidth - 64; // Account for all paddings

    return Scaffold(
      appBar: AppBar(
        title: Text(favorite.title),
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
                    if (favorite.reasoningContent != null) ...[
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
