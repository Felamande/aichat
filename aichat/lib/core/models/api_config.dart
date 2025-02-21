import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:dio/dio.dart';

part 'api_config.g.dart';

@HiveType(typeId: 2)
class ApiConfig {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String baseUrl;

  @HiveField(3)
  final String apiKey;

  @HiveField(4)
  final String defaultModel;

  @HiveField(5)
  final bool isEnabled;

  @HiveField(6)
  final Map<String, dynamic> additionalHeaders;

  @HiveField(7)
  final List<String> availableModels;

  ApiConfig({
    String? id,
    required this.name,
    required this.baseUrl,
    required this.apiKey,
    required this.defaultModel,
    this.isEnabled = true,
    Map<String, dynamic>? additionalHeaders,
    List<String>? availableModels,
  })  : id = id ?? const Uuid().v4(),
        additionalHeaders = additionalHeaders ?? {},
        availableModels = availableModels ?? [];

  ApiConfig copyWith({
    String? name,
    String? baseUrl,
    String? apiKey,
    String? defaultModel,
    bool? isEnabled,
    Map<String, dynamic>? additionalHeaders,
    List<String>? availableModels,
  }) {
    return ApiConfig(
      id: id,
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      defaultModel: defaultModel ?? this.defaultModel,
      isEnabled: isEnabled ?? this.isEnabled,
      additionalHeaders: additionalHeaders ?? this.additionalHeaders,
      availableModels: availableModels ?? this.availableModels,
    );
  }

  Future<List<String>> fetchAvailableModels() async {
    try {
      final dio = Dio();
      final response = await dio.get(
        '$baseUrl/v1/models',
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            ...additionalHeaders,
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'baseUrl': baseUrl,
      'apiKey': apiKey,
      'defaultModel': defaultModel,
      'isEnabled': isEnabled,
      'additionalHeaders': additionalHeaders,
      'availableModels': availableModels,
    };
  }

  factory ApiConfig.fromJson(Map<String, dynamic> json) {
    return ApiConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      baseUrl: json['baseUrl'] as String,
      apiKey: json['apiKey'] as String,
      defaultModel: json['defaultModel'] as String,
      isEnabled: json['isEnabled'] as bool? ?? true,
      additionalHeaders:
          json['additionalHeaders'] as Map<String, dynamic>? ?? {},
      availableModels: (json['availableModels'] as List?)?.cast<String>() ?? [],
    );
  }
}
