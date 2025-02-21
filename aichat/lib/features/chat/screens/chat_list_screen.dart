import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../widgets/chat_card.dart';
import '../../../core/models/chat.dart';
import 'chat_screen.dart';
import '../../search/screens/search_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../../core/services/api_config_service.dart';
import '../../favorites/controllers/favorites_controller.dart';

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
    return AlertDialog(
      title: const Text('New Chat'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Chat Title',
              hintText: 'Enter a title for your chat',
            ),
            onSubmitted: (_) => _createChat(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _createChat,
          child: const Text('Create'),
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
        onChatCreated: (chatId) => _navigateToChat(context, chatId),
      ),
    );
  }

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    Chat chat,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chat'),
        content: Text(
          'Are you sure you want to delete "${chat.title}"?\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (result == true) {
      await ref.read(chatListProvider.notifier).removeChat(chat.id);
      await ref
          .read(favoritesControllerProvider.notifier)
          .removeAllForChat(chat.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chat deleted'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showChatOptions(BuildContext context, WidgetRef ref, Chat chat) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Duplicate Chat'),
              onTap: () async {
                await ref.read(chatListProvider.notifier).duplicateChat(chat);
                Navigator.pop(context);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Chat duplicated'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete,
                color: theme.colorScheme.error,
              ),
              title: Text(
                'Delete Chat',
                style: TextStyle(
                  color: theme.colorScheme.error,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context, ref, chat);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToChat(BuildContext context, String chatId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(chatId: chatId),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chats = ref.watch(chatListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SearchScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: chats.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No chats yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start a new conversation',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final chat = chats[index];
                return ChatCard(
                  chat: chat,
                  onTap: () => _navigateToChat(context, chat.id),
                  onLongPress: () => _showChatOptions(context, ref, chat),
                  onDelete: () => _showDeleteConfirmation(context, ref, chat),
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
