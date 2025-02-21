import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/api_config.dart';

final apiConfigServiceProvider = Provider((ref) => ApiConfigService());

class ApiConfigService {
  Future<Box<ApiConfig>> _getBox() async {
    return await Hive.openBox<ApiConfig>('api_configs');
  }

  Future<List<ApiConfig>> getAllConfigs() async {
    final box = await _getBox();
    return box.values.toList();
  }

  Future<ApiConfig?> getDefaultConfig() async {
    final box = await Hive.openBox<ApiConfig>('api_configs');
    if (box.isEmpty) return null;
    return box.values.first;
  }

  Future<void> addConfig(ApiConfig config) async {
    final box = await _getBox();
    await box.put(config.id, config);
  }

  Future<void> updateConfig(ApiConfig config) async {
    final box = await _getBox();
    await box.put(config.id, config);
  }

  Future<void> deleteConfig(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }

  Future<void> setDefaultConfig(String id) async {
    final box = await Hive.openBox<ApiConfig>('api_configs');
    final config = box.get(id);
    if (config != null) {
      // Move the selected config to the first position
      await box.delete(id);
      await box.put(id, config);
    }
  }

  // Future<List<String>> getAvailableModels(ApiConfig config) async {
  //   try {
  //     final models = await config.fetchAvailableModels();
  //     if (models.isNotEmpty) {
  //       await updateConfig(config.copyWith(availableModels: models));
  //     }
  //     return models;
  //   } catch (e) {
  //     return [];
  //   }
  // }
}
