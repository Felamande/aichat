import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/chat_controller.dart';
import '../widgets/message_bubble.dart';
import '../../favorites/controllers/favorites_controller.dart';
import '../../../core/models/message.dart';
import '../../../core/models/chat.dart';
import '../../../core/models/api_config.dart';
import '../../../core/services/api_config_service.dart';
import '../../../core/services/chat_service.dart';
import '../../../l10n/translations.dart';

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
  bool _shouldAutoScroll = true;
  bool _isSending = false;
  // List<String> _availableModels = [];

  @override
  void initState() {
    super.initState();
    _loadAvailableModels();
    _scrollController.addListener(_scrollListener);
    // Initial scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  Future<void> _loadAvailableModels() async {
    final apiConfig =
        await ref.read(apiConfigServiceProvider).getDefaultConfig();
    if (apiConfig != null) {
      // final models =
      //     await ref.read(chatServiceProvider).fetchAvailableModels(apiConfig);
      if (mounted) {
        setState(() {
          // _availableModels = models;
        });
      }
    }
  }

  void _showApiSelector(Chat chat) async {
    final apiConfigs = await ref.read(apiConfigServiceProvider).getAllConfigs();
    final currentConfig = apiConfigs.firstWhere(
      (config) => config.id == chat.apiConfigId,
      orElse: () => apiConfigs.first,
    );

    if (!mounted) return;

    final selectedConfig = await showDialog<ApiConfig>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select API'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: apiConfigs.length,
            itemBuilder: (context, index) {
              final config = apiConfigs[index];
              return RadioListTile<ApiConfig>(
                title: Text(config.name),
                subtitle: Text(config.baseUrl),
                value: config,
                groupValue: currentConfig,
                onChanged: (value) {
                  Navigator.pop(context, value);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selectedConfig != null && selectedConfig.id != chat.apiConfigId) {
      // Update chat with new API config and model
      final updatedChat = chat.copyWith(
        apiConfigId: selectedConfig.id,
        modelId: selectedConfig.defaultModel,
      );

      // Update in controller
      await ref
          .read(chatControllerProvider(widget.chatId).notifier)
          .updateChat(updatedChat);

      // Set as default config
      await ref
          .read(apiConfigServiceProvider)
          .setDefaultConfig(selectedConfig.id);

      if (mounted) {
        setState(() {}); // Trigger rebuild
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;
      // Only auto-scroll if we're very close to the bottom
      _shouldAutoScroll = (maxScroll - currentScroll) <= 20;
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients && _shouldAutoScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _handleSubmitted(String text) {
    if (text.isEmpty) return;

    _messageController.clear();
    setState(() {
      _isComposing = false;
      _shouldAutoScroll = true; // Force scroll to bottom for new messages
    });

    ref.read(chatControllerProvider(widget.chatId).notifier).sendMessage(text);
    _scrollToBottom();
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

  Widget _buildMessageList(Chat chat) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8.0),
      itemCount: chat.messages.length,
      itemBuilder: (context, index) {
        final message = chat.messages[index];
        final isFavorite = ref.watch(favoritesControllerProvider).any(
              (item) => item.id == message.id && !item.isChat,
            );

        return MessageBubble(
          message: message,
          isFavorite: isFavorite,
          onCopy: (content) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Message copied to clipboard'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          onFavorite: () {
            ref
                .read(favoritesControllerProvider.notifier)
                .toggleFavorite(chat, message);
          },
          onDelete: () {
            ref
                .read(chatControllerProvider(widget.chatId).notifier)
                .deleteMessage(message.id);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatControllerProvider(widget.chatId));
    final favorites = ref.watch(favoritesControllerProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: chatState.when(
          data: (chat) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(chat.title),
              FutureBuilder<List<ApiConfig>>(
                future: ref.read(apiConfigServiceProvider).getAllConfigs(),
                builder: (context, snapshot) {
                  final apiConfig = snapshot.data?.firstWhere(
                    (config) => config.id == chat.apiConfigId,
                    orElse: () => snapshot.data?.first ?? ApiConfig.empty(),
                  );
                  return GestureDetector(
                    onTap: () => _showApiSelector(chat),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          apiConfig?.name ?? 'No API Selected',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        Icon(
                          Icons.arrow_drop_down,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                          size: 16,
                        ),
                      ],
                    ),
                  );
                },
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
                child: const Text('Select API'),
                onTap: () {
                  chatState.whenData((chat) {
                    Future.microtask(() => _showApiSelector(chat));
                  });
                },
              ),
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
                  : _buildMessageList(chat),
            ),
            const Divider(height: 1),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                children: [
                  chatState.when(
                    data: (chat) => Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.api),
                          tooltip: l10n.get('select_api'),
                          onPressed: () => _showApiSelector(chat),
                        ),
                        IconButton(
                          icon: const Icon(Icons.splitscreen),
                          tooltip: l10n.get('clear_context'),
                          onPressed: () {
                            ref
                                .read(chatControllerProvider(widget.chatId)
                                    .notifier)
                                .clearContext();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_sweep),
                          tooltip: l10n.get('clear_messages'),
                          onPressed: () {
                            ref
                                .read(chatControllerProvider(widget.chatId)
                                    .notifier)
                                .clearMessages();
                          },
                        ),
                        if (ref
                            .watch(
                                chatControllerProvider(widget.chatId).notifier)
                            .isSending)
                          IconButton(
                            icon: const Icon(Icons.stop),
                            tooltip: l10n.get('stop_generating'),
                            onPressed: () {
                              ref
                                  .read(chatControllerProvider(widget.chatId)
                                      .notifier)
                                  .cancelStream();
                            },
                          ),
                        const Spacer(),
                        Text(
                          chat.modelId,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                    loading: () => const SizedBox(),
                    error: (_, __) => const SizedBox(),
                  ),
                  Row(
                    children: [
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
                            hintText: l10n.get('type_message'),
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
