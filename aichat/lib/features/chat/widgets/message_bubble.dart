import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/message.dart';
import '../../../core/services/attachment_service.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final VoidCallback? onLongPress;

  const MessageBubble({
    super.key,
    required this.message,
    this.onLongPress,
  });

  Widget _buildAttachment(BuildContext context, Attachment attachment) {
    final theme = Theme.of(context);
    final isImage = attachment.mimeType.startsWith('image/');
    final isVideo = attachment.mimeType.startsWith('video/');
    final isAudio = attachment.mimeType.startsWith('audio/');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () async {
          final uri = Uri.file(attachment.path);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isImage
                      ? Icons.image
                      : isVideo
                          ? Icons.video_library
                          : isAudio
                              ? Icons.audiotrack
                              : Icons.attach_file,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attachment.name,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${(attachment.size / 1024).toStringAsFixed(1)} KB',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: GestureDetector(
          onLongPress: onLongPress,
          child: Card(
            color: isUser
                ? theme.colorScheme.primary
                : theme.colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.reasoning != null) ...[
                    Text(
                      'Reasoning: ${message.reasoning}',
                      style: TextStyle(
                        color: isUser
                            ? theme.colorScheme.onPrimary.withOpacity(0.7)
                            : theme.colorScheme.onSecondaryContainer
                                .withOpacity(0.7),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (message.attachments.isNotEmpty) ...[
                    ...message.attachments
                        .map((a) => _buildAttachment(context, a)),
                    const SizedBox(height: 8),
                  ],
                  MarkdownBody(
                    data: message.content,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(
                        color: isUser
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSecondaryContainer,
                      ),
                      code: TextStyle(
                        backgroundColor: isUser
                            ? theme.colorScheme.onPrimary.withOpacity(0.1)
                            : theme.colorScheme.onSecondaryContainer
                                .withOpacity(0.1),
                        color: isUser
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat.jm().format(message.timestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color: isUser
                              ? theme.colorScheme.onPrimary.withOpacity(0.7)
                              : theme.colorScheme.onSecondaryContainer
                                  .withOpacity(0.7),
                        ),
                      ),
                      if (message.isError) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.error_outline,
                          size: 16,
                          color: theme.colorScheme.error,
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
    );
  }
}
