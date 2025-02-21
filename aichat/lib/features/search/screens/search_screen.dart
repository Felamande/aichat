import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/services/search_service.dart';
import '../../chat/screens/chat_screen.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');
final searchResultsProvider =
    FutureProvider.autoDispose<List<SearchResult>>((ref) {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) return [];
  final searchService = ref.read(searchServiceProvider);
  return searchService.search(query);
});

class SearchScreen extends ConsumerWidget {
  final String? chatId;

  const SearchScreen({super.key, this.chatId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final results = ref.watch(searchResultsProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          decoration: InputDecoration(
            hintText:
                chatId != null ? 'Search in chat' : 'Search chats and messages',
            border: InputBorder.none,
            hintStyle:
                TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
          ),
          style: theme.textTheme.titleMedium,
          onChanged: (value) {
            ref.read(searchQueryProvider.notifier).state = value;
          },
        ),
      ),
      body: results.when(
        data: (items) => items.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search,
                      size: 64,
                      color: theme.colorScheme.primary.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No results found',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Try different keywords',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final result = items[index];
                  return ListTile(
                    leading: Icon(
                      result.isMessageMatch ? Icons.message : Icons.chat,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(
                      result.isMessageMatch
                          ? 'Message in ${result.chat.title}'
                          : result.chat.title,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.matchText,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat.yMd().add_jm().format(
                                result.isMessageMatch
                                    ? result.message!.timestamp
                                    : result.chat.updatedAt,
                              ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            chatId: result.chat.id,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }
}
