import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/models/api_config.dart';
import '../../../core/services/settings_service.dart';
import '../../../l10n/translations.dart';
import 'api_settings_screen.dart';

final themeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);
final languageProvider = StateNotifierProvider<LanguageNotifier, Locale>((ref) {
  return LanguageNotifier(ref);
});

class LanguageNotifier extends StateNotifier<Locale> {
  final Ref ref;

  LanguageNotifier(this.ref) : super(const Locale('en')) {
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final savedLanguage = await ref.read(settingsServiceProvider).getLanguage();
    if (savedLanguage != null) {
      state = Locale(savedLanguage);
    }
  }

  Future<void> setLanguage(Locale locale) async {
    await ref.read(settingsServiceProvider).setLanguage(locale.languageCode);
    state = locale;
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeProvider);
    final language = ref.watch(languageProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('settings')),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.api),
            title: Text(l10n.get('api_settings')),
            subtitle: Text(l10n.get('api_settings_desc')),
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
            title: Text(l10n.get('theme')),
            subtitle: Text(
              themeMode == ThemeMode.system
                  ? l10n.get('system')
                  : themeMode == ThemeMode.light
                      ? l10n.get('light')
                      : l10n.get('dark'),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(l10n.get('choose_theme')),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RadioListTile<ThemeMode>(
                        title: Text(l10n.get('system')),
                        value: ThemeMode.system,
                        groupValue: themeMode,
                        onChanged: (value) {
                          ref.read(themeProvider.notifier).state = value!;
                          Navigator.pop(context);
                        },
                      ),
                      RadioListTile<ThemeMode>(
                        title: Text(l10n.get('light')),
                        value: ThemeMode.light,
                        groupValue: themeMode,
                        onChanged: (value) {
                          ref.read(themeProvider.notifier).state = value!;
                          Navigator.pop(context);
                        },
                      ),
                      RadioListTile<ThemeMode>(
                        title: Text(l10n.get('dark')),
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
            title: Text(l10n.get('language')),
            subtitle: Text(
              language.languageCode == 'en'
                  ? l10n.get('english')
                  : l10n.get('chinese'),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(l10n.get('choose_language')),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RadioListTile<Locale>(
                        title: Text(l10n.get('english')),
                        value: const Locale('en'),
                        groupValue: language,
                        onChanged: (value) {
                          ref
                              .read(languageProvider.notifier)
                              .setLanguage(value!);
                          Navigator.pop(context);
                        },
                      ),
                      RadioListTile<Locale>(
                        title: Text(l10n.get('chinese')),
                        value: const Locale('zh'),
                        groupValue: language,
                        onChanged: (value) {
                          ref
                              .read(languageProvider.notifier)
                              .setLanguage(value!);
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
