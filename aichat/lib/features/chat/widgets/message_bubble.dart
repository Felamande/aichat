import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/message.dart';
import '../../../core/services/attachment_service.dart';
import 'package:flutter/rendering.dart';
import '../../../l10n/translations.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final Function(String)? onCopy;
  final VoidCallback? onDelete;
  final VoidCallback? onFavorite;
  final bool isFavorite;
  final VoidCallback? onTap;
  final bool isSelected;
  final VoidCallback? onSelect;
  final AppLocalizations l10n;

  const MessageBubble({
    super.key,
    required this.message,
    this.onCopy,
    this.onDelete,
    this.onFavorite,
    this.isFavorite = false,
    this.onTap,
    this.isSelected = false,
    this.onSelect,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isUser;

    if (message.isSplit) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
        child: Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                l10n.get('context_split'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                ),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
      );
    }

    if (message.isError) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: theme.colorScheme.error,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message.content,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: GestureDetector(
            onLongPress: onSelect,
            onTap: onSelect ?? onTap,
            child: Container(
              margin:
                  const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.8,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primaryContainer
                    : message.isSplit
                        ? theme.colorScheme.surfaceVariant.withOpacity(0.5)
                        : isUser
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Material(
                color: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.attachments.isNotEmpty)
                        for (final attachment in message.attachments)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: _buildAttachment(context, attachment),
                          ),
                      if (message.reasoningContent != null &&
                          message.reasoningContent!.trim().isNotEmpty) ...[
                        Container(
                          width: MediaQuery.of(context).size.width * 0.7,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isUser
                                ? theme.colorScheme.primaryContainer
                                    .withOpacity(0.5)
                                : theme.colorScheme.surface.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: GptMarkdown(
                            message.reasoningContent!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isUser
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Container(
                        width: MediaQuery.of(context).size.width * 0.7,
                        child: GptMarkdown(
                          message.content,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: isUser
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            DateFormat.jm().format(message.timestamp),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isUser
                                  ? theme.colorScheme.onPrimary.withOpacity(0.7)
                                  : theme.colorScheme.onSurfaceVariant
                                      .withOpacity(0.7),
                            ),
                          ),
                          if (!isUser && message.apiConfigName != null) ...[
                            Text(
                              ' • ',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant
                                    .withOpacity(0.7),
                              ),
                            ),
                            Text(
                              message.apiConfigName!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant
                                    .withOpacity(0.7),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (!isSelected) ...[
                            IconButton(
                              icon: const Icon(Icons.copy, size: 18),
                              onPressed: () async {
                                await Clipboard.setData(
                                    ClipboardData(text: message.content));
                                if (onCopy != null) {
                                  onCopy!(message.content);
                                }
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                isFavorite ? Icons.star : Icons.star_border,
                                size: 18,
                              ),
                              onPressed: onFavorite,
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 18),
                              onPressed: onDelete,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (isSelected)
          Positioned(
            top: 8,
            right: isUser ? 16 : null,
            left: isUser ? null : 16,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                size: 16,
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAttachment(BuildContext context, Attachment attachment) {
    final theme = Theme.of(context);
    final isImage = attachment.mimeType.startsWith('image/');
    final isVideo = attachment.mimeType.startsWith('video/');
    final isAudio = attachment.mimeType.startsWith('audio/');

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          isImage
              ? Icons.image
              : isVideo
                  ? Icons.video_library
                  : isAudio
                      ? Icons.audiotrack
                      : Icons.attach_file,
        ),
        title: Text(
          attachment.name,
          style: theme.textTheme.bodyMedium,
        ),
        subtitle: Text(
          '${(attachment.size / 1024).toStringAsFixed(1)} KB',
          style: theme.textTheme.bodySmall,
        ),
      ),
    );
  }
}
