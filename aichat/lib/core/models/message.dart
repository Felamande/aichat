import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'message.g.dart';

@HiveType(typeId: 3)
class Attachment {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String path;

  @HiveField(3)
  final String mimeType;

  @HiveField(4)
  final int size;

  Attachment({
    String? id,
    required this.name,
    required this.path,
    required this.mimeType,
    required this.size,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'path': path,
        'mimeType': mimeType,
        'size': size,
      };

  factory Attachment.fromJson(Map<String, dynamic> json) => Attachment(
        id: json['id'] as String,
        name: json['name'] as String,
        path: json['path'] as String,
        mimeType: json['mimeType'] as String,
        size: json['size'] as int,
      );
}

@HiveType(typeId: 0)
class Message {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String content;

  @HiveField(2)
  final bool isUser;

  @HiveField(3)
  final DateTime timestamp;

  @HiveField(4)
  final String? reasoning;

  @HiveField(5)
  final bool isError;

  @HiveField(6)
  final List<Attachment> attachments;

  Message({
    String? id,
    required this.content,
    required this.isUser,
    DateTime? timestamp,
    this.reasoning,
    this.isError = false,
    List<Attachment>? attachments,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now(),
        attachments = attachments ?? [];

  Message copyWith({
    String? content,
    bool? isUser,
    DateTime? timestamp,
    String? reasoning,
    bool? isError,
    List<Attachment>? attachments,
  }) {
    return Message(
      id: id,
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      reasoning: reasoning ?? this.reasoning,
      isError: isError ?? this.isError,
      attachments: attachments ?? this.attachments,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'reasoning': reasoning,
      'isError': isError,
      'attachments': attachments.map((a) => a.toJson()).toList(),
    };
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      content: json['content'] as String,
      isUser: json['isUser'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
      reasoning: json['reasoning'] as String?,
      isError: json['isError'] as bool? ?? false,
      attachments: (json['attachments'] as List?)
              ?.map((a) => Attachment.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
