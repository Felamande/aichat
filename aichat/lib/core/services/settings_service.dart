import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final settingsServiceProvider = Provider((ref) => SettingsService());

class SettingsService {
  static const String _settingsBoxName = 'settings';
  static const String _languageKey = 'language';

  Future<Box> _getBox() async {
    return await Hive.openBox(_settingsBoxName);
  }

  Future<void> setLanguage(String languageCode) async {
    final box = await _getBox();
    await box.put(_languageKey, languageCode);
  }

  Future<String?> getLanguage() async {
    final box = await _getBox();
    return box.get(_languageKey) as String?;
  }
}
