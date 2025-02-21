import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/message.dart';
import '../../../core/services/attachment_service.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final VoidCallback? onTap;

  const MessageBubble({
    super.key,
    required this.message,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12.0),
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
                  MarkdownBody(
                    data: message.content,
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(
                        color: isUser
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      code: TextStyle(
                        backgroundColor: isUser
                            ? theme.colorScheme.primaryContainer
                            : theme.colorScheme.surface,
                        color: isUser
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    onTapLink: (text, href, title) async {
                      if (href != null) {
                        final url = Uri.parse(href);
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat.jm().format(message.timestamp),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isUser
                          ? theme.colorScheme.onPrimary.withOpacity(0.7)
                          : theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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
