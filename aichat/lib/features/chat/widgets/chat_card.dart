import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import '../../../core/models/chat.dart';
import '../../../l10n/translations.dart';

class ChatCard extends StatelessWidget {
  final Chat chat;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onLongPress;
  final AppLocalizations l10n;
  final bool isFavorite;

  const ChatCard({
    super.key,
    required this.chat,
    required this.onTap,
    required this.onDelete,
    required this.onLongPress,
    required this.l10n,
    required this.isFavorite,
  });

  String get lastMessagePreview {
    if (chat.messages.isEmpty) {
      return l10n.get('no_messages_preview');
    }
    final lastMessage = chat.messages.last;
    final content = lastMessage.content.trim();
    if (content.isEmpty) {
      return l10n.get('no_messages_preview');
    }
    return content.length > 50 ? '${content.substring(0, 50)}...' : content;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Slidable(
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
            icon: Icons.delete,
            label: l10n.get('delete'),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          color: isFavorite
              ? theme.colorScheme.primaryContainer.withOpacity(0.1)
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isFavorite
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.primaryContainer.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(
                          Icons.chat,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      if (isFavorite)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Icon(
                            Icons.star,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              chat.title,
                              style: theme.textTheme.titleMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            DateFormat.yMd().format(chat.updatedAt),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lastMessagePreview,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
