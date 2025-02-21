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
  final List<Message> messages;

  FavoriteItem({
    required this.id,
    required this.title,
    required this.content,
    this.reasoningContent,
    required this.timestamp,
    required this.isChat,
    this.chatId,
    this.messages = const [],
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
      messages: [message],
    );
  }

  factory FavoriteItem.fromMessages(List<Message> messages, Chat chat) {
    return FavoriteItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: chat.title,
      content: messages.map((m) => m.content).join('\n\n'),
      timestamp: messages.last.timestamp,
      isChat: false,
      chatId: chat.id,
      messages: messages,
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
      'messages': messages.map((m) => m.toJson()).toList(),
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
      messages: (json['messages'] as List?)
              ?.map((m) => Message.fromJson(Map<String, dynamic>.from(m)))
              .toList() ??
          [],
    );
  }
}
