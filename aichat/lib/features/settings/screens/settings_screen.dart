import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/models/api_config.dart';
import 'api_settings_screen.dart';

final themeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);
final languageProvider = StateProvider<Locale>((ref) => const Locale('en'));

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeProvider);
    final language = ref.watch(languageProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.api),
            title: const Text('API Settings'),
            subtitle: const Text('Manage API endpoints and keys'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ApiSettingsScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.color_lens),
            title: const Text('Theme'),
            subtitle: Text(
              themeMode == ThemeMode.system
                  ? 'System'
                  : themeMode == ThemeMode.light
                      ? 'Light'
                      : 'Dark',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Choose Theme'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RadioListTile<ThemeMode>(
                        title: const Text('System'),
                        value: ThemeMode.system,
                        groupValue: themeMode,
                        onChanged: (value) {
                          ref.read(themeProvider.notifier).state = value!;
                          Navigator.pop(context);
                        },
                      ),
                      RadioListTile<ThemeMode>(
                        title: const Text('Light'),
                        value: ThemeMode.light,
                        groupValue: themeMode,
                        onChanged: (value) {
                          ref.read(themeProvider.notifier).state = value!;
                          Navigator.pop(context);
                        },
                      ),
                      RadioListTile<ThemeMode>(
                        title: const Text('Dark'),
                        value: ThemeMode.dark,
                        groupValue: themeMode,
                        onChanged: (value) {
                          ref.read(themeProvider.notifier).state = value!;
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            subtitle: Text(language.languageCode == 'en' ? 'English' : '中文'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Choose Language'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RadioListTile<Locale>(
                        title: const Text('English'),
                        value: const Locale('en'),
                        groupValue: language,
                        onChanged: (value) {
                          ref.read(languageProvider.notifier).state = value!;
                          Navigator.pop(context);
                        },
                      ),
                      RadioListTile<Locale>(
                        title: const Text('中文'),
                        value: const Locale('zh'),
                        groupValue: language,
                        onChanged: (value) {
                          ref.read(languageProvider.notifier).state = value!;
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
