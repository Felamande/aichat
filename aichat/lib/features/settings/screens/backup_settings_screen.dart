import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/models/chat.dart';
import '../../../core/models/api_config.dart';
import '../../../l10n/translations.dart';

class BackupSettingsScreen extends ConsumerWidget {
  const BackupSettingsScreen({super.key});

  Future<void> _exportData(BuildContext context) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/aichat_backup.json');

      final data = {
        'chats': (await Hive.openBox<Chat>('chats'))
            .values
            .map((chat) => chat.toJson())
            .toList(),
        'api_configs': (await Hive.openBox<ApiConfig>('api_configs'))
            .values
            .map((config) => config.toJson())
            .toList(),
      };

      await file.writeAsString(jsonEncode(data));
      await Share.shareXFiles([XFile(file.path)], subject: 'AIChat Backup');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _importData(BuildContext context) async {
    try {
      // Show warning dialog first
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppLocalizations.of(context).get('import_warning')),
          content: Text(
            AppLocalizations.of(context).get('import_warning'),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context).get('cancel')),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: Text(AppLocalizations.of(context).get('proceed')),
            ),
          ],
        ),
      );

      if (proceed != true) return;

      // Pick file using FilePicker
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.first.path!);
      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      // Validate the backup file format
      if (!data.containsKey('chats') || !data.containsKey('api_configs')) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(AppLocalizations.of(context).get('invalid_backup_file')),
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      // Clear existing data
      final chatsBox = await Hive.openBox<Chat>('chats');
      final apiConfigsBox = await Hive.openBox<ApiConfig>('api_configs');
      final favoritesBox = await Hive.openBox<Map>('favorites');

      await chatsBox.clear();
      await apiConfigsBox.clear();
      await favoritesBox.clear();

      // Import chats
      final chats = (data['chats'] as List).map((chatJson) {
        return Chat.fromJson(chatJson as Map<String, dynamic>);
      }).toList();

      // Import API configs
      final apiConfigs = (data['api_configs'] as List).map((configJson) {
        return ApiConfig.fromJson(configJson as Map<String, dynamic>);
      }).toList();

      // Save to Hive
      for (final chat in chats) {
        await chatsBox.put(chat.id, chat);
      }

      for (final config in apiConfigs) {
        await apiConfigsBox.put(config.id, config);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).get('import_success')),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('backup_restore')),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.upload),
            title: Text(l10n.get('export_data')),
            subtitle: Text(l10n.get('export_data_desc')),
            onTap: () => _exportData(context),
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: Text(l10n.get('import_data')),
            subtitle: Text(l10n.get('import_data_desc')),
            onTap: () => _importData(context),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              l10n.get('import_warning'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
