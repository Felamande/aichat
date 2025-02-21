import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'message.dart';

part 'chat.g.dart';

@HiveType(typeId: 1)
class Chat {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final List<Message> messages;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final DateTime updatedAt;

  @HiveField(5)
  final String modelId;

  @HiveField(6)
  final bool isPinned;

  Chat({
    String? id,
    required this.title,
    List<Message>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
    required this.modelId,
    this.isPinned = false,
  }) : id = id ?? const Uuid().v4(),
       messages = messages ?? [],
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Chat copyWith({
    String? title,
    List<Message>? messages,
    DateTime? updatedAt,
    String? modelId,
    bool? isPinned,
  }) {
    return Chat(
      id: id,
      title: title ?? this.title,
      messages: messages ?? this.messages,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      modelId: modelId ?? this.modelId,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'messages': messages.map((m) => m.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'modelId': modelId,
      'isPinned': isPinned,
    };
  }

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'] as String,
      title: json['title'] as String,
      messages:
          (json['messages'] as List)
              .map((m) => Message.fromJson(m as Map<String, dynamic>))
              .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      modelId: json['modelId'] as String,
      isPinned: json['isPinned'] as bool? ?? false,
    );
  }
}
