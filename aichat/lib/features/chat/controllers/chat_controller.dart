import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/models/chat.dart';
import '../../../core/models/message.dart';
import '../../../core/services/chat_service.dart';
import '../../../core/models/api_config.dart';
import '../../../core/services/attachment_service.dart';

enum ChatStatus {
  idle,
  sending,
  error,
}

final chatControllerProvider =
    StateNotifierProvider.family<ChatController, AsyncValue<Chat>, String>(
        (ref, chatId) {
  final chatService = ref.watch(chatServiceProvider);
  return ChatController(chatId, chatService, ref);
});

class ChatController extends StateNotifier<AsyncValue<Chat>> {
  final String chatId;
  final ChatService _chatService;
  final Ref _ref;

  ChatController(this.chatId, this._chatService, this._ref)
      : super(const AsyncValue.loading()) {
    _loadChat();
  }

  Future<void> _loadChat() async {
    try {
      final box = await Hive.openBox<Chat>('chats');
      final chat = box.get(chatId);
      if (chat != null) {
        state = AsyncValue.data(chat);
      } else {
        state = AsyncValue.error('Chat not found', StackTrace.current);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateChat(Chat chat) async {
    try {
      final box = await Hive.openBox<Chat>('chats');
      await box.put(chat.id, chat);
      state = AsyncValue.data(chat);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> sendMessage(String content) async {
    if (state.isLoading) return;

    final previousState = state.value;
    if (previousState == null) return;

    final userMessage = Message(
      content: content,
      isUser: true,
    );

    // Update state with user message
    state = AsyncValue.data(previousState.copyWith(
      messages: [...previousState.messages, userMessage],
      updatedAt: DateTime.now(),
    ));

    // Save to Hive
    await _saveChat(state.value!);

    // Get API config
    final apiConfigBox = await Hive.openBox<ApiConfig>('api_configs');
    final apiConfig = apiConfigBox.values.first;

    try {
      // Create a placeholder assistant message
      final assistantMessage = Message(
        content: '',
        isUser: false,
        apiConfigName: apiConfig.name,
      );

      // Add the empty assistant message to the chat
      state = AsyncValue.data(state.value!.copyWith(
        messages: [...state.value!.messages, assistantMessage],
        updatedAt: DateTime.now(),
      ));

      // Get context messages
      final contextMessages = _getContextMessages(previousState.messages);

      // Start streaming the response
      final streamController = await _chatService.sendMessageStream(
        content: content,
        modelId: previousState.modelId,
        previousMessages: contextMessages,
        apiConfig: apiConfig,
      );

      await for (final update in streamController) {
        if (update.isComplete) {
          // Final update with complete message
          final updatedMessages = [...state.value!.messages];
          updatedMessages[updatedMessages.length - 1] = update.message.copyWith(
            apiConfigName: apiConfig.name,
          );

          state = AsyncValue.data(state.value!.copyWith(
            messages: updatedMessages,
            updatedAt: DateTime.now(),
          ));

          // Save to Hive only on completion
          await _saveChat(state.value!);
        } else {
          // Intermediate update
          final updatedMessages = [...state.value!.messages];
          updatedMessages[updatedMessages.length - 1] = update.message.copyWith(
            apiConfigName: apiConfig.name,
          );

          state = AsyncValue.data(state.value!.copyWith(
            messages: updatedMessages,
            updatedAt: DateTime.now(),
          ));
        }
      }
    } catch (e, stack) {
      final errorMessage = Message(
        content: 'Failed to send message: ${e.toString()}',
        isUser: false,
        isError: true,
        apiConfigName: apiConfig.name,
      );

      state = AsyncValue.data(previousState.copyWith(
        messages: [...previousState.messages, userMessage, errorMessage],
        updatedAt: DateTime.now(),
      ));

      // Save to Hive
      await _saveChat(state.value!);
    }
  }

  Future<void> _saveChat(Chat chat) async {
    final box = await Hive.openBox<Chat>('chats');
    await box.put(chat.id, chat);
  }

  Future<void> clearContext() async {
    if (state.isLoading) return;

    final previousState = state.value;
    if (previousState == null) return;

    // If the last message is a split, remove it
    if (previousState.messages.isNotEmpty &&
        previousState.messages.last.isSplit) {
      state = AsyncValue.data(previousState.copyWith(
        messages: previousState.messages
            .sublist(0, previousState.messages.length - 1),
        updatedAt: DateTime.now(),
      ));
    } else {
      // Add a split message
      final splitMessage = Message(
        content: '--- Context Split ---',
        isUser: false,
        isSplit: true,
      );

      state = AsyncValue.data(previousState.copyWith(
        messages: [...previousState.messages, splitMessage],
        updatedAt: DateTime.now(),
      ));
    }

    // Save to Hive
    await _saveChat(state.value!);
  }

  Future<void> clearMessages() async {
    if (state.isLoading) return;

    final previousState = state.value;
    if (previousState == null) return;

    state = AsyncValue.data(previousState.copyWith(
      messages: [],
      updatedAt: DateTime.now(),
    ));

    // Save to Hive
    await _saveChat(state.value!);
  }

  List<Message> _getContextMessages(List<Message> messages) {
    // Find the last split message
    final lastSplitIndex = messages.lastIndexWhere((m) => m.isSplit);
    if (lastSplitIndex == -1) {
      return messages;
    }
    return messages.sublist(lastSplitIndex + 1);
  }

  Future<void> deleteMessage(String messageId) async {
    if (state.isLoading) return;

    final previousState = state.value;
    if (previousState == null) return;

    state = AsyncValue.data(previousState.copyWith(
      messages: previousState.messages.where((m) => m.id != messageId).toList(),
      updatedAt: DateTime.now(),
    ));

    // Save to Hive
    await _saveChat(state.value!);
  }

  Future<void> addAttachment(File file) async {
    if (state.isLoading) return;

    final previousState = state.value;
    if (previousState == null) return;

    try {
      final attachmentService = _ref.read(attachmentServiceProvider);
      final attachment = await attachmentService.saveFile(file);

      final message = Message(
        content: 'Attached file: ${attachment.name}',
        isUser: true,
        attachments: [attachment],
      );

      state = AsyncValue.data(previousState.copyWith(
        messages: [...previousState.messages, message],
        updatedAt: DateTime.now(),
      ));

      await _saveChat(state.value!);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteAttachment(String messageId, String attachmentId) async {
    if (state.isLoading) return;

    final previousState = state.value;
    if (previousState == null) return;

    try {
      final message =
          previousState.messages.firstWhere((m) => m.id == messageId);
      final attachment =
          message.attachments.firstWhere((a) => a.id == attachmentId);

      final attachmentService = _ref.read(attachmentServiceProvider);
      await attachmentService.deleteAttachment(attachment);

      final updatedMessage = message.copyWith(
        attachments:
            message.attachments.where((a) => a.id != attachmentId).toList(),
      );

      state = AsyncValue.data(previousState.copyWith(
        messages: previousState.messages
            .map((m) => m.id == messageId ? updatedMessage : m)
            .toList(),
        updatedAt: DateTime.now(),
      ));

      await _saveChat(state.value!);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
