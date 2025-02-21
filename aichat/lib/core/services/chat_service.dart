import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/api_config.dart';
import '../models/message.dart';

final chatServiceProvider = Provider((ref) => ChatService(ref));

class MessageUpdate {
  final Message message;
  final bool isComplete;

  MessageUpdate(this.message, this.isComplete);
}

class ChatService {
  final Ref _ref;
  final Dio _dio;

  ChatService(this._ref) : _dio = Dio();

  Future<Message> sendMessage({
    required String content,
    required String modelId,
    required List<Message> previousMessages,
    required ApiConfig apiConfig,
  }) async {
    try {
      final messages = previousMessages
          .map((msg) => {
                'role': msg.isUser ? 'user' : 'assistant',
                'content': msg.content,
              })
          .toList();

      messages.add({
        'role': 'user',
        'content': content,
      });
      print(
          "${apiConfig.apiKey}, ${apiConfig.baseUrl}, ${modelId}, ${messages}");
      final response = await _dio.post(
        '${apiConfig.baseUrl}/chat/completions',
        data: {
          'model': modelId,
          'messages': messages,
          'stream': true,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer ${apiConfig.apiKey}',
            ...apiConfig.additionalHeaders,
          },
          responseType: ResponseType.stream,
        ),
      );

      final stream = response.data.stream as Stream<Uint8List>;
      final buffer = StringBuffer();
      final reasonBuffer = StringBuffer();

      String? reasoning;
      String? reasoningContent;

      await for (final chunk in stream.transform(
        StreamTransformer<Uint8List, String>.fromHandlers(
          handleData: (Uint8List data, EventSink<String> sink) {
            final string = utf8.decode(data);
            sink.add(string);
          },
        ),
      )) {
        print("get chunk: $chunk");
        // Split chunk into lines and process each line
        final lines = chunk.split('\n');
        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6).trim();
            if (data == '[DONE]') break;

            try {
              final json = jsonDecode(data);
              final delta = json['choices'][0]['delta'];

              if (delta.containsKey('content')) {
                print("get content: ${delta['content']}");
                if (delta['content'] != null) {
                  buffer.write(delta['content']);
                }
              }

              if (delta.containsKey('function_call')) {
                reasoning = delta['function_call']['name'];
              }

              if (delta.containsKey('reasoning_content')) {
                reasoningContent = delta['reasoning_content'];
                if (reasoningContent != null) {
                  reasonBuffer.write(reasoningContent);
                }
              }
            } catch (e) {
              // Skip invalid JSON
            }
          }
        }
      }

      return Message(
        content: buffer.toString(),
        isUser: false,
        reasoning: reasoning,
        reasoningContent: reasonBuffer.toString(),
      );
    } on DioException catch (e) {
      final response = e.response;
      String errorMessage;
      int errorCode = response?.statusCode ?? 0;

      if (response?.data != null) {
        errorMessage = response?.data is Map<String, dynamic>
            ? (response?.data['error']?['message'] ?? response?.data.toString())
            : response?.data.toString() ?? e.message ?? 'Unknown error';
      } else {
        errorMessage = e.message ?? 'Unknown error';
      }

      return Message(
        content:
            'Error ($errorCode):\n$errorMessage\n\nResponse: ${response?.data}',
        isUser: false,
        isError: true,
        apiConfigName: apiConfig.name,
      );
    } catch (e) {
      return Message(
        content: 'An unexpected error occurred: $e',
        isUser: false,
        isError: true,
        apiConfigName: apiConfig.name,
      );
    }
  }

  Future<bool> testConnection(ApiConfig config) async {
    try {
      final response = await _dio.get(
        "${config.baseUrl}/models",
        options: Options(
          headers: {
            'Authorization': 'Bearer ${config.apiKey}',
            ...config.additionalHeaders,
          },
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Future<List<String>> fetchAvailableModels(ApiConfig config) async {
  //   try {
  //     final response = await _dio.get(
  //       '${config.baseUrl}/models',
  //       options: Options(
  //         headers: {
  //           'Authorization': 'Bearer ${config.apiKey}',
  //           ...config.additionalHeaders,
  //         },
  //       ),
  //     );

  //     if (response.statusCode == 200) {
  //       final models = (response.data['data'] as List)
  //           .map((model) => model['id'] as String)
  //           .toList();
  //       print("get models in chat service: $models");
  //       return models;
  //     }
  //     return [];
  //   } catch (e) {
  //     return [];
  //   }
  // }

  Future<Stream<MessageUpdate>> sendMessageStream({
    required String content,
    required String modelId,
    required List<Message> previousMessages,
    required ApiConfig apiConfig,
  }) async {
    final controller = StreamController<MessageUpdate>();

    try {
      final messages = previousMessages
          .map((msg) => {
                'role': msg.isUser ? 'user' : 'assistant',
                'content': msg.content,
              })
          .toList();

      messages.add({
        'role': 'user',
        'content': content,
      });

      final response = await _dio.post(
        '${apiConfig.baseUrl}/chat/completions',
        data: {
          'model': modelId,
          'messages': messages,
          'stream': true,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer ${apiConfig.apiKey}',
            ...apiConfig.additionalHeaders,
          },
          responseType: ResponseType.stream,
        ),
      );

      final stream = response.data.stream as Stream<Uint8List>;
      final buffer = StringBuffer();
      final reasonBuffer = StringBuffer();
      String? reasoning;

      stream.transform(
        StreamTransformer<Uint8List, String>.fromHandlers(
          handleData: (Uint8List data, EventSink<String> sink) {
            final string = utf8.decode(data);
            sink.add(string);
          },
        ),
      ).listen(
        (chunk) {
          print("get chunk: $chunk");
          final lines = chunk.split('\n');
          for (final line in lines) {
            if (line.startsWith('data: ')) {
              final data = line.substring(6).trim();
              if (data == '[DONE]') {
                controller.add(MessageUpdate(
                  Message(
                    content: buffer.toString(),
                    isUser: false,
                    reasoning: reasoning,
                    reasoningContent: reasonBuffer.toString(),
                  ),
                  true,
                ));
                controller.close();
                return;
              }

              try {
                final json = jsonDecode(data);
                final delta = json['choices'][0]['delta'];

                if (delta.containsKey('content')) {
                  final newContent = delta['content'];
                  if (newContent != null && newContent != '') {
                    buffer.write(newContent);
                    controller.add(MessageUpdate(
                      Message(
                        content: buffer.toString(),
                        isUser: false,
                        reasoning: reasoning,
                        reasoningContent: reasonBuffer.toString(),
                      ),
                      false,
                    ));
                  }
                }

                if (delta.containsKey('function_call')) {
                  reasoning = delta['function_call']['name'];
                }

                if (delta.containsKey('reasoning_content')) {
                  final newContent = delta['reasoning_content'];
                  if (newContent != null && newContent != '') {
                    reasonBuffer.write(newContent);
                    controller.add(MessageUpdate(
                      Message(
                        content: buffer.toString(),
                        isUser: false,
                        reasoning: reasoning,
                        reasoningContent: reasonBuffer.toString(),
                      ),
                      false,
                    ));
                  }
                }
              } catch (e) {
                // Skip invalid JSON
              }
            }
          }
        },
        onError: (error) {
          print("get error: $error");
          controller.addError(error);
          controller.close();
        },
        cancelOnError: true,
      );

      return controller.stream;
    } catch (e) {
      print("get error 1: $e");
      controller.addError(e);
      controller.close();
      rethrow;
    }
  }
}
