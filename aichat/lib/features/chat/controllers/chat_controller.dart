import 'dart:io';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/models/chat.dart';
import '../../../core/models/message.dart';
import '../../../core/services/chat_service.dart';
import '../../../core/models/api_config.dart';
import '../../../core/services/attachment_service.dart';
import '../screens/chat_list_screen.dart';

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
  StreamSubscription? _messageSubscription;
  bool _isSending = false;

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
      // Update both state and chat list
      state = AsyncValue.data(chat);
      _ref.read(chatListProvider.notifier).updateChat(chat);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> sendMessage(String content) async {
    if (state.isLoading || _isSending) return;
    _isSending = true;

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

    // Save to Hive and update chat list
    await _saveChat(state.value!);

    // Get API config using the chat's apiConfigId
    final apiConfigBox = await Hive.openBox<ApiConfig>('api_configs');
    final apiConfig = apiConfigBox.values.firstWhere(
      (config) => config.id == previousState.apiConfigId,
      orElse: () =>
          apiConfigBox.values.first, // Fallback to first config if not found
    );

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

      _messageSubscription = streamController.listen(
        (update) {
          if (update.isComplete) {
            final updatedMessages = [...state.value!.messages];
            updatedMessages[updatedMessages.length - 1] =
                update.message.copyWith(
              apiConfigName: apiConfig.name,
            );

            state = AsyncValue.data(state.value!.copyWith(
              messages: updatedMessages,
              updatedAt: DateTime.now(),
            ));

            _saveChat(state.value!);
            _isSending = false;
          } else {
            final updatedMessages = [...state.value!.messages];
            updatedMessages[updatedMessages.length - 1] =
                update.message.copyWith(
              apiConfigName: apiConfig.name,
            );

            state = AsyncValue.data(state.value!.copyWith(
              messages: updatedMessages,
              updatedAt: DateTime.now(),
            ));
          }
        },
        onError: (error) {
          _isSending = false;
          final errorMessage = Message(
            content: 'Failed to send message: ${error.toString()}',
            isUser: false,
            isError: true,
            apiConfigName: apiConfig.name,
          );

          state = AsyncValue.data(previousState.copyWith(
            messages: [...previousState.messages, userMessage, errorMessage],
            updatedAt: DateTime.now(),
          ));

          _saveChat(state.value!);
        },
        onDone: () {
          _isSending = false;
          _messageSubscription = null;
        },
      );
    } catch (e, stack) {
      _isSending = false;
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

      _saveChat(state.value!);
    }
  }

  Future<void> _saveChat(Chat chat) async {
    final box = await Hive.openBox<Chat>('chats');
    await box.put(chat.id, chat);
    // Update the chat list to refresh the sorting
    _ref.read(chatListProvider.notifier).updateChat(chat);
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

  void cancelStream() {
    if (_isSending && state.value != null) {
      // Save the current state of the last message before cancelling
      final messages = [...state.value!.messages];
      if (messages.isNotEmpty) {
        final lastMessage = messages.last;
        if (!lastMessage.isUser && lastMessage.content.isNotEmpty) {
          // Save the partial response
          state = AsyncValue.data(state.value!.copyWith(
            messages: messages,
            updatedAt: DateTime.now(),
          ));
          _saveChat(state.value!);
        }
      }
    }
    _messageSubscription?.cancel();
    _messageSubscription = null;
    _isSending = false;
  }

  @override
  void dispose() {
    cancelStream();
    super.dispose();
  }

  bool get isSending => _isSending;
}
