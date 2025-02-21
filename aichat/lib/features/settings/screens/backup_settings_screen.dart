import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
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
