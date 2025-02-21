import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/chat.dart';
import '../models/message.dart';

final searchServiceProvider = Provider((ref) => SearchService());

class SearchResult {
  final Chat chat;
  final Message? message;
  final String matchText;
  final bool isMessageMatch;

  SearchResult({
    required this.chat,
    this.message,
    required this.matchText,
    required this.isMessageMatch,
  });
}

class SearchService {
  Future<List<SearchResult>> search(String query) async {
    if (query.isEmpty) return [];

    final results = <SearchResult>[];
    final box = await Hive.openBox<Chat>('chats');
    final chats = box.values.toList();

    final queryLower = query.toLowerCase();

    for (final chat in chats) {
      // Search in chat title
      if (chat.title.toLowerCase().contains(queryLower)) {
        results.add(SearchResult(
          chat: chat,
          matchText: chat.title,
          isMessageMatch: false,
        ));
      }

      // Search in messages
      for (final message in chat.messages) {
        if (message.content.toLowerCase().contains(queryLower)) {
          results.add(SearchResult(
            chat: chat,
            message: message,
            matchText: message.content,
            isMessageMatch: true,
          ));
        }
      }
    }

    // Sort results: chats first, then messages, both by date
    results.sort((a, b) {
      if (a.isMessageMatch == b.isMessageMatch) {
        final aDate =
            a.isMessageMatch ? a.message!.timestamp : a.chat.updatedAt;
        final bDate =
            b.isMessageMatch ? b.message!.timestamp : b.chat.updatedAt;
        return bDate.compareTo(aDate); // Most recent first
      }
      return a.isMessageMatch ? 1 : -1; // Chats before messages
    });

    return results;
  }

  Future<List<SearchResult>> searchInChat(String query, String chatId) async {
    if (query.isEmpty) return [];

    final results = <SearchResult>[];
    final box = await Hive.openBox<Chat>('chats');
    final chat = box.get(chatId);

    if (chat == null) return [];

    final queryLower = query.toLowerCase();

    // Search in messages
    for (final message in chat.messages) {
      if (message.content.toLowerCase().contains(queryLower)) {
        results.add(SearchResult(
          chat: chat,
          message: message,
          matchText: message.content,
          isMessageMatch: true,
        ));
      }
    }

    // Sort by date, most recent first
    results
        .sort((a, b) => b.message!.timestamp.compareTo(a.message!.timestamp));

    return results;
  }
}
