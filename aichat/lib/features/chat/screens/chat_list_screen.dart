import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../widgets/chat_card.dart';
import '../../../core/models/chat.dart';
import '../../../core/models/api_config.dart';
import 'chat_screen.dart';
import '../../search/screens/search_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../../core/services/api_config_service.dart';
import '../../favorites/controllers/favorites_controller.dart';
import '../../../l10n/translations.dart';

final chatListProvider =
    StateNotifierProvider<ChatListNotifier, List<Chat>>((ref) {
  return ChatListNotifier();
});

class ChatListNotifier extends StateNotifier<List<Chat>> {
  ChatListNotifier() : super([]) {
    _loadChats();
  }

  Future<void> _loadChats() async {
    final box = await Hive.openBox<Chat>('chats');
    state = box.values.toList();
  }

  Future<void> addChat(Chat chat) async {
    final box = await Hive.openBox<Chat>('chats');
    await box.put(chat.id, chat);
    state = [...state, chat];
  }

  Future<void> removeChat(String id) async {
    final box = await Hive.openBox<Chat>('chats');
    await box.delete(id);
    state = state.where((chat) => chat.id != id).toList();
  }

  Future<void> updateChat(Chat chat) async {
    final box = await Hive.openBox<Chat>('chats');
    await box.put(chat.id, chat);
    state = state.map((c) => c.id == chat.id ? chat : c).toList();
  }

  Future<void> duplicateChat(Chat chat) async {
    final newChat = Chat(
      title: '${chat.title} (Copy)',
      modelId: chat.modelId,
      messages: chat.messages,
    );
    await addChat(newChat);
  }

  Future<void> createChat() async {
    final apiConfig = await Hive.openBox<ApiConfig>('api_configs');
    final defaultConfig = apiConfig.values.firstOrNull;

    final chat = Chat(
      title: 'New Chat',
      modelId: defaultConfig?.defaultModel ?? 'gpt-3.5-turbo',
    );
    await addChat(chat);
  }
}

class _NewChatDialog extends StatefulWidget {
  final WidgetRef ref;
  final Function(String) onChatCreated;

  const _NewChatDialog({
    required this.ref,
    required this.onChatCreated,
  });

  @override
  State<_NewChatDialog> createState() => _NewChatDialogState();
}

class _NewChatDialogState extends State<_NewChatDialog> {
  late final TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _createChat() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final apiConfig =
        await widget.ref.read(apiConfigServiceProvider).getDefaultConfig();
    final chat = Chat(
      title: title,
      modelId: apiConfig?.defaultModel ?? 'gpt-3.5-turbo',
    );
    await widget.ref.read(chatListProvider.notifier).addChat(chat);

    if (mounted) {
      Navigator.pop(context);
      widget.onChatCreated(chat.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.get('new_chat')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            autofocus: true,
            decoration: InputDecoration(
              labelText: l10n.get('chat_title'),
              hintText: l10n.get('chat_title_hint'),
            ),
            onSubmitted: (_) => _createChat(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.get('cancel')),
        ),
        TextButton(
          onPressed: _createChat,
          child: Text(l10n.get('create')),
        ),
      ],
    );
  }
}

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  void _showNewChatDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => _NewChatDialog(
        ref: ref,
        onChatCreated: (chatId) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(chatId: chatId),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chats = ref.watch(chatListProvider);
    final favorites = ref.watch(favoritesControllerProvider);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    // Sort chats: favorites first, then by last message time
    final sortedChats = [...chats];
    sortedChats.sort((a, b) {
      final aIsFavorite =
          favorites.any((item) => item.id == a.id && item.isChat);
      final bIsFavorite =
          favorites.any((item) => item.id == b.id && item.isChat);

      // If both are favorites or both are not favorites, sort by last message time
      if (aIsFavorite == bIsFavorite) {
        final aLastMessageTime =
            a.messages.isEmpty ? a.updatedAt : a.messages.last.timestamp;
        final bLastMessageTime =
            b.messages.isEmpty ? b.updatedAt : b.messages.last.timestamp;
        return bLastMessageTime.compareTo(aLastMessageTime);
      }

      // Keep favorites at the top
      if (aIsFavorite) return -1;
      if (bIsFavorite) return 1;
      return 0;
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('chats')),
      ),
      body: chats.isEmpty
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
                    l10n.get('no_chats'),
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.get('start_new_chat'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: sortedChats.length,
              itemBuilder: (context, index) {
                final chat = sortedChats[index];
                final isFavorite =
                    favorites.any((item) => item.id == chat.id && item.isChat);

                return ChatCard(
                  chat: chat,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(chatId: chat.id),
                      ),
                    );
                  },
                  onDelete: () async {
                    final shouldDelete = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(l10n.get('delete_chat')),
                        content: Text(l10n.get('delete_confirm')),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(l10n.get('cancel')),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: theme.colorScheme.error,
                            ),
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(l10n.get('delete')),
                          ),
                        ],
                      ),
                    );

                    if (shouldDelete == true) {
                      ref.read(chatListProvider.notifier).removeChat(chat.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.get('chat_deleted')),
                          ),
                        );
                      }
                    }
                  },
                  onLongPress: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: Icon(
                                isFavorite ? Icons.star : Icons.star_outline,
                              ),
                              title: Text(
                                isFavorite
                                    ? l10n.get('remove_from_favorites')
                                    : l10n.get('add_to_favorites'),
                              ),
                              onTap: () {
                                ref
                                    .read(favoritesControllerProvider.notifier)
                                    .toggleChatFavorite(chat);
                                Navigator.pop(context);
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.copy),
                              title: Text(l10n.get('duplicate_chat')),
                              onTap: () {
                                ref
                                    .read(chatListProvider.notifier)
                                    .duplicateChat(chat);
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(l10n.get('chat_duplicated')),
                                  ),
                                );
                              },
                            ),
                            ListTile(
                              leading: Icon(
                                Icons.delete,
                                color: isFavorite
                                    ? theme.colorScheme.error.withOpacity(0.5)
                                    : theme.colorScheme.error,
                              ),
                              title: Text(
                                l10n.get('delete_chat'),
                                style: TextStyle(
                                  color: isFavorite
                                      ? theme.colorScheme.error.withOpacity(0.5)
                                      : theme.colorScheme.error,
                                ),
                              ),
                              enabled: !isFavorite,
                              onTap: isFavorite
                                  ? null
                                  : () async {
                                      Navigator.pop(
                                          context); // Close bottom sheet first
                                      final shouldDelete =
                                          await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Text(l10n.get('delete_chat')),
                                          content:
                                              Text(l10n.get('delete_confirm')),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: Text(l10n.get('cancel')),
                                            ),
                                            TextButton(
                                              style: TextButton.styleFrom(
                                                foregroundColor:
                                                    theme.colorScheme.error,
                                              ),
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: Text(l10n.get('delete')),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (shouldDelete == true &&
                                          context.mounted) {
                                        ref
                                            .read(chatListProvider.notifier)
                                            .removeChat(chat.id);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content:
                                                Text(l10n.get('chat_deleted')),
                                          ),
                                        );
                                      }
                                    },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  l10n: l10n,
                  isFavorite: isFavorite,
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewChatDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
}
