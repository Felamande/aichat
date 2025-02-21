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
  bool _isNearBottom = true;
  late AppLocalizations l10n;
  static const double _scrollThreshold =
      100.0; // Distance from bottom to consider "near bottom"

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    // Remove the initial scroll to bottom since we'll handle it in didChangeDependencies
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
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
      // Check if we're near the bottom
      _isNearBottom = (maxScroll - currentScroll) <= _scrollThreshold;

      // Only allow auto-scroll if we're very close to the bottom
      setState(() {
        _shouldAutoScroll = _isNearBottom;
      });
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;

    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _handleSubmitted(String text) {
    if (text.isEmpty) return;

    _messageController.clear();
    setState(() {
      _isComposing = false;
      _shouldAutoScroll = true; // Reset auto-scroll when sending new message
      _isNearBottom = true;
    });

    ref.read(chatControllerProvider(widget.chatId).notifier).sendMessage(text);
    _scrollToBottom();
  }

  Future<void> _copyMessageToClipboard(String content) async {
    await Clipboard.setData(ClipboardData(text: content));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).get('message_copied')),
          duration: const Duration(seconds: 2),
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
              title: Text(AppLocalizations.of(context).get('copy_message')),
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
                isFavorite
                    ? AppLocalizations.of(context).get('remove_from_favorites')
                    : AppLocalizations.of(context).get('add_to_favorites'),
              ),
              onTap: () {
                ref
                    .read(favoritesControllerProvider.notifier)
                    .toggleMessageFavorite(message, chat);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete,
                color: theme.colorScheme.error,
              ),
              title: Text(
                AppLocalizations.of(context).get('delete_message'),
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
      SnackBar(
        content:
            Text(AppLocalizations.of(context).get('file_attachments_disabled')),
        duration: const Duration(seconds: 2),
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
              SnackBar(
                content:
                    Text(AppLocalizations.of(context).get('message_copied')),
                duration: const Duration(seconds: 2),
              ),
            );
          },
          onFavorite: () {
            ref
                .read(favoritesControllerProvider.notifier)
                .toggleMessageFavorite(message, chat);
          },
          onDelete: () {
            ref
                .read(chatControllerProvider(widget.chatId).notifier)
                .deleteMessage(message.id);
          },
          l10n: AppLocalizations.of(context),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    l10n = AppLocalizations.of(context);
    final chatState = ref.watch(chatControllerProvider(widget.chatId));

    // Move the chat state watching logic here
    ref.listen<AsyncValue<Chat>>(chatControllerProvider(widget.chatId),
        (previous, next) {
      next.whenData((chat) {
        if (_shouldAutoScroll && _isNearBottom) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        }
      });
    });

    final favorites = ref.watch(favoritesControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: chatState.when(
          data: (chat) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => _showEditTitleDialog(chat),
                child: Row(
                  children: [
                    Expanded(child: Text(chat.title)),
                    Icon(
                      Icons.edit,
                      size: 16,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ],
                ),
              ),
              FutureBuilder<List<ApiConfig>>(
                future: ref.read(apiConfigServiceProvider).getAllConfigs(),
                builder: (context, snapshot) {
                  final apiConfig = snapshot.data?.firstWhere(
                    (config) => config.id == chat.apiConfigId,
                    orElse: () => snapshot.data?.first ?? ApiConfig.empty(),
                  );
                  return GestureDetector(
                    onTap: ref
                            .watch(
                                chatControllerProvider(widget.chatId).notifier)
                            .isSending
                        ? null
                        : () => _showApiSelector(chat),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          apiConfig?.name ?? l10n.get('no_api_selected'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(ref
                                    .watch(chatControllerProvider(widget.chatId)
                                        .notifier)
                                    .isSending
                                ? 0.4
                                : 0.6),
                          ),
                        ),
                        Icon(
                          Icons.arrow_drop_down,
                          color: theme.colorScheme.onSurface.withOpacity(ref
                                  .watch(chatControllerProvider(widget.chatId)
                                      .notifier)
                                  .isSending
                              ? 0.4
                              : 0.6),
                          size: 16,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          loading: () => Text(l10n.get('loading')),
          error: (error, _) => Text('${l10n.get('error_prefix')}$error'),
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
                    .toggleChatFavorite(chat);
              },
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.all(8),
            ),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
          PopupMenuButton(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            icon: const Icon(Icons.more_vert),
            enabled: !ref
                .watch(chatControllerProvider(widget.chatId).notifier)
                .isSending,
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: !ref
                    .watch(chatControllerProvider(widget.chatId).notifier)
                    .isSending,
                child: Text(l10n.get('select_api')),
                onTap: () {
                  chatState.whenData((chat) {
                    Future.microtask(() => _showApiSelector(chat));
                  });
                },
              ),
              PopupMenuItem(
                enabled: !ref
                    .watch(chatControllerProvider(widget.chatId).notifier)
                    .isSending,
                child: Text(l10n.get('clear_context_menu')),
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
                            l10n.get('no_messages_title'),
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.get('start_conversation'),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    )
                  : MessageList(
                      chat: chat,
                      scrollController: _scrollController,
                      l10n: l10n,
                    ),
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
                          onPressed: ref
                                  .watch(chatControllerProvider(widget.chatId)
                                      .notifier)
                                  .isSending
                              ? null
                              : () => _showApiSelector(chat),
                        ),
                        IconButton(
                          icon: const Icon(Icons.splitscreen),
                          tooltip: l10n.get('clear_context'),
                          onPressed: ref
                                  .watch(chatControllerProvider(widget.chatId)
                                      .notifier)
                                  .isSending
                              ? null
                              : () {
                                  ref
                                      .read(
                                          chatControllerProvider(widget.chatId)
                                              .notifier)
                                      .clearContext();
                                },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_sweep),
                          tooltip: l10n.get('clear_messages'),
                          onPressed: ref
                                  .watch(chatControllerProvider(widget.chatId)
                                      .notifier)
                                  .isSending
                              ? null
                              : () {
                                  ref
                                      .read(
                                          chatControllerProvider(widget.chatId)
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
        error: (error, _) =>
            Center(child: Text('${l10n.get('error_prefix')}$error')),
      ),
    );
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
        title: Text(AppLocalizations.of(context).get('select_api_title')),
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
            child: Text(AppLocalizations.of(context).get('cancel')),
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

  void _showConfigDialog({ApiConfig? config, bool isCopy = false}) {
    final nameController = TextEditingController(
        text: isCopy ? "${config?.name} (Copy)" : config?.name);
    final urlController = TextEditingController(text: config?.baseUrl);
    final apiKeyController = TextEditingController(text: config?.apiKey);
    final modelController =
        TextEditingController(text: config?.defaultModel ?? 'gpt-3.5-turbo');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.get(isCopy
            ? 'copy_api_config'
            : config == null
                ? 'add_api_config'
                : 'edit_api_config')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: l10n.get('api_name'),
                hintText: l10n.get('api_name_hint'),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: urlController,
              decoration: InputDecoration(
                labelText: l10n.get('base_url'),
                hintText: l10n.get('base_url_hint'),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: apiKeyController,
              decoration: InputDecoration(
                labelText: l10n.get('api_key'),
                hintText: l10n.get('api_key_hint'),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: modelController,
              decoration: InputDecoration(
                labelText: l10n.get('default_model'),
                hintText: l10n.get('default_model_hint'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.get('cancel')),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty &&
                  urlController.text.isNotEmpty &&
                  apiKeyController.text.isNotEmpty &&
                  modelController.text.isNotEmpty) {
                final newConfig = ApiConfig(
                  id: isCopy ? null : config?.id, // Preserve ID when editing
                  name: nameController.text,
                  baseUrl: urlController.text,
                  apiKey: apiKeyController.text,
                  defaultModel: modelController.text,
                  additionalHeaders:
                      config?.additionalHeaders, // Preserve additional headers
                  availableModels:
                      config?.availableModels, // Preserve available models
                );

                if (isCopy || config == null) {
                  await ref.read(apiConfigServiceProvider).addConfig(newConfig);
                } else {
                  await ref
                      .read(apiConfigServiceProvider)
                      .updateConfig(newConfig);
                }

                if (mounted) {
                  Navigator.pop(context);
                  setState(() {});
                }
              }
            },
            child: Text(isCopy
                ? l10n.get('create')
                : config == null
                    ? l10n.get('add')
                    : l10n.get('save')),
          ),
        ],
      ),
    );
  }

  void _showEditTitleDialog(Chat chat) {
    final titleController = TextEditingController(text: chat.title);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.get('chat_title')),
        content: TextField(
          controller: titleController,
          decoration: InputDecoration(
            hintText: l10n.get('chat_title_hint'),
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
                final updatedChat = chat.copyWith(
                  title: titleController.text.trim(),
                );
                await ref
                    .read(chatControllerProvider(widget.chatId).notifier)
                    .updateChat(updatedChat);
                if (mounted) {
                  Navigator.pop(context);
                }
              }
            },
            child: Text(l10n.get('save')),
          ),
        ],
      ),
    );
  }
}

class MessageList extends ConsumerWidget {
  final Chat chat;
  final ScrollController scrollController;
  final AppLocalizations l10n;

  const MessageList({
    super.key,
    required this.chat,
    required this.scrollController,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      controller: scrollController,
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
              SnackBar(
                content: Text(l10n.get('message_copied')),
                duration: const Duration(seconds: 2),
              ),
            );
          },
          onFavorite: () {
            ref
                .read(favoritesControllerProvider.notifier)
                .toggleMessageFavorite(message, chat);
          },
          onDelete: () {
            ref
                .read(chatControllerProvider(chat.id).notifier)
                .deleteMessage(message.id);
          },
          l10n: l10n,
        );
      },
    );
  }
}
