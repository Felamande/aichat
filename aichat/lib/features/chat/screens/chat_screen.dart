import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/chat_controller.dart';
import '../widgets/message_bubble.dart';
import '../../favorites/controllers/favorites_controller.dart';
import '../../../core/models/message.dart';
import '../../../core/models/chat.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;

  const ChatScreen({super.key, required this.chatId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isComposing = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSubmitted(String text) {
    if (text.isEmpty) return;

    _messageController.clear();
    setState(() {
      _isComposing = false;
    });

    ref.read(chatControllerProvider(widget.chatId).notifier).sendMessage(text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _copyMessageToClipboard(String content) async {
    await Clipboard.setData(ClipboardData(text: content));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showMessageOptions(BuildContext context, Message message, Chat chat) {
    final theme = Theme.of(context);
    final isFavorite = ref.read(favoritesControllerProvider).any(
          (item) => item.id == message.id && !item.isChat,
        );

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy Message'),
              onTap: () {
                _copyMessageToClipboard(message.content);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                isFavorite ? Icons.star : Icons.star_outline,
              ),
              title: Text(
                isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
              ),
              onTap: () {
                ref
                    .read(favoritesControllerProvider.notifier)
                    .toggleFavorite(chat, message);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete,
                color: theme.colorScheme.error,
              ),
              title: Text(
                'Delete Message',
                style: TextStyle(
                  color: theme.colorScheme.error,
                ),
              ),
              onTap: () {
                ref
                    .read(chatControllerProvider(widget.chatId).notifier)
                    .deleteMessage(message.id);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleAttachment() async {
    // Temporarily disabled
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('File attachments are temporarily disabled'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatControllerProvider(widget.chatId));
    final favorites = ref.watch(favoritesControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: chatState.when(
          data: (chat) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(chat.title),
              Text(
                chat.modelId,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
          loading: () => const Text('Loading...'),
          error: (error, _) => Text('Error: $error'),
        ),
        actions: [
          chatState.when(
            data: (chat) => IconButton(
              icon: Icon(
                favorites.any((item) => item.id == chat.id && item.isChat)
                    ? Icons.star
                    : Icons.star_outline,
              ),
              onPressed: () {
                ref
                    .read(favoritesControllerProvider.notifier)
                    .toggleFavorite(chat);
              },
            ),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Text('Clear Context'),
                onTap: () {
                  ref
                      .read(chatControllerProvider(widget.chatId).notifier)
                      .clearContext();
                },
              ),
            ],
          ),
        ],
      ),
      body: chatState.when(
        data: (chat) => Column(
          children: [
            Expanded(
              child: chat.messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: theme.colorScheme.primary.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No messages yet',
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start the conversation',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(8.0),
                      itemCount: chat.messages.length,
                      itemBuilder: (context, index) {
                        final message = chat.messages[index];
                        return MessageBubble(
                          message: message,
                          onTap: () =>
                              _showMessageOptions(context, message, chat),
                        );
                      },
                    ),
            ),
            const Divider(height: 1),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file),
                    onPressed: _handleAttachment,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      onChanged: (text) {
                        setState(() {
                          _isComposing = text.isNotEmpty;
                        });
                      },
                      onSubmitted: _isComposing ? _handleSubmitted : null,
                      decoration: InputDecoration(
                        hintText: 'Type a message',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _isComposing
                        ? () => _handleSubmitted(_messageController.text)
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
