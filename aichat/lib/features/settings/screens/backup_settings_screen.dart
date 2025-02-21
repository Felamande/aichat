import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/models/chat.dart';
import '../../../core/models/api_config.dart';

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
    // Temporarily disabled
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Import functionality is temporarily disabled'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.upload),
            title: const Text('Export Data'),
            subtitle: const Text('Save your chats and settings'),
            onTap: () => _exportData(context),
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Import Data'),
            subtitle: const Text('Restore from backup'),
            onTap: () => _importData(context),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Warning: Importing data will replace all existing chats and settings.',
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
