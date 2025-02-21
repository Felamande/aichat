import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/api_config.dart';
import '../models/message.dart';

final chatServiceProvider = Provider((ref) => ChatService(ref));

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
        apiConfig.baseUrl,
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
      String? reasoning;

      await for (final chunk in stream.transform(
        StreamTransformer<Uint8List, String>.fromHandlers(
          handleData: (Uint8List data, EventSink<String> sink) {
            final string = utf8.decode(data);
            sink.add(string);
          },
        ),
      )) {
        if (chunk.startsWith('data: ')) {
          final data = chunk.substring(6);
          if (data == '[DONE]') break;

          try {
            final json = jsonDecode(data);
            final delta = json['choices'][0]['delta'];

            if (delta.containsKey('content')) {
              print("get content: ${delta['content']}");
              buffer.write(delta['content']);
            }

            if (delta.containsKey('function_call')) {
              reasoning = delta['function_call']['name'];
            }
          } catch (e) {
            // Skip invalid JSON
          }
        }
      }

      return Message(
        content: buffer.toString(),
        isUser: false,
        reasoning: reasoning,
      );
    } on DioException catch (e) {
      return Message(
        content: 'Error: ${e.message}',
        isUser: false,
        isError: true,
      );
    } catch (e) {
      return Message(
        content: 'An unexpected error occurred: ${e}',
        isUser: false,
        isError: true,
      );
    }
  }

  Future<bool> testConnection(ApiConfig config) async {
    try {
      final response = await _dio.get(
        config.baseUrl,
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

  Future<List<String>> fetchAvailableModels(ApiConfig config) async {
    try {
      final response = await _dio.get(
        '${config.baseUrl}/v1/models',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${config.apiKey}',
            ...config.additionalHeaders,
          },
        ),
      );

      if (response.statusCode == 200) {
        final models = (response.data['data'] as List)
            .map((model) => model['id'] as String)
            .toList();
        return models;
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
