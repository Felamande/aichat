import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/models/api_config.dart';
import '../../../core/services/api_config_service.dart';

class ApiSettingsScreen extends ConsumerStatefulWidget {
  const ApiSettingsScreen({super.key});

  @override
  ConsumerState<ApiSettingsScreen> createState() => _ApiSettingsScreenState();
}

class _ApiSettingsScreenState extends ConsumerState<ApiSettingsScreen> {
  void _showConfigDialog({ApiConfig? config, bool isCopy = false}) {
    final nameController = TextEditingController(
        text: isCopy ? "${config?.name} (Copy)" : config?.name);
    final urlController = TextEditingController(text: config?.baseUrl);
    final apiKeyController = TextEditingController(text: config?.apiKey);
    final modelController =
        TextEditingController(text: config?.defaultModel ?? 'gpt-3.5-turbo');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isCopy
            ? 'Copy API Configuration'
            : config == null
                ? 'Add API Configuration'
                : 'Edit API Configuration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g., OpenAI API',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'Base URL',
                hintText: 'e.g., https://api.openai.com',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: apiKeyController,
              decoration: const InputDecoration(
                labelText: 'API Key',
                hintText: 'Enter your API key',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: modelController,
              decoration: const InputDecoration(
                labelText: 'Default Model',
                hintText: 'e.g., gpt-3.5-turbo',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty &&
                  urlController.text.isNotEmpty &&
                  apiKeyController.text.isNotEmpty &&
                  modelController.text.isNotEmpty) {
                final newConfig = ApiConfig(
                  name: nameController.text,
                  baseUrl: urlController.text,
                  apiKey: apiKeyController.text,
                  defaultModel: modelController.text,
                );

                if (isCopy || config == null) {
                  await ref.read(apiConfigServiceProvider).addConfig(newConfig);
                } else {
                  await ref
                      .read(apiConfigServiceProvider)
                      .updateConfig(newConfig);
                }

                if (mounted) {
                  Navigator.pop(context);
                  setState(() {});
                }
              }
            },
            child: Text(isCopy
                ? 'Create Copy'
                : config == null
                    ? 'Add'
                    : 'Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteDialog(ApiConfig config) async {
    final configs = await ref.read(apiConfigServiceProvider).getAllConfigs();

    // Don't allow deleting if it's the only config
    if (configs.length <= 1) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot delete the only API configuration'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    final delete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Configuration'),
        content: Text(
            'Are you sure you want to delete "${config.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (delete == true && mounted) {
      await ref.read(apiConfigServiceProvider).deleteConfig(config.id);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showConfigDialog(),
          ),
        ],
      ),
      body: FutureBuilder<Box<ApiConfig>>(
        future: Hive.openBox<ApiConfig>('api_configs'),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final configs = snapshot.data!.values.toList();
          return configs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.api_outlined,
                        size: 64,
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No API configurations found',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add an API configuration to get started',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                            ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: configs.length,
                  itemBuilder: (context, index) {
                    final config = configs[index];
                    return ListTile(
                      title: Text(config.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(config.baseUrl),
                          Text(
                            'Model: ${config.defaultModel}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.copy),
                            onPressed: () =>
                                _showConfigDialog(config: config, isCopy: true),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showConfigDialog(config: config),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _showDeleteDialog(config),
                          ),
                        ],
                      ),
                      isThreeLine: true,
                    );
                  },
                );
        },
      ),
    );
  }
}
