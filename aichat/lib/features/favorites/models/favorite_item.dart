import '../../../core/models/chat.dart';
import '../../../core/models/message.dart';

class FavoriteItem {
  final String id;
  final String title;
  final String content;
  final String? reasoningContent;
  final DateTime timestamp;
  final bool isChat;
  final String? chatId;

  FavoriteItem({
    required this.id,
    required this.title,
    required this.content,
    this.reasoningContent,
    required this.timestamp,
    required this.isChat,
    this.chatId,
  });

  factory FavoriteItem.fromChat(Chat chat) {
    return FavoriteItem(
      id: chat.id,
      title: chat.title,
      content:
          chat.messages.isNotEmpty ? chat.messages.last.content : 'No messages',
      timestamp: chat.updatedAt,
      isChat: true,
    );
  }

  factory FavoriteItem.fromMessage(Message message, Chat chat) {
    return FavoriteItem(
      id: message.id,
      title: chat.title,
      content: message.content,
      reasoningContent: message.reasoningContent,
      timestamp: message.timestamp,
      isChat: false,
      chatId: chat.id,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'reasoningContent': reasoningContent,
      'timestamp': timestamp.toIso8601String(),
      'isChat': isChat,
      'chatId': chatId,
    };
  }

  factory FavoriteItem.fromJson(Map<String, dynamic> json) {
    return FavoriteItem(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      reasoningContent: json['reasoningContent'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isChat: json['isChat'] as bool,
      chatId: json['chatId'] as String?,
    );
  }
}
