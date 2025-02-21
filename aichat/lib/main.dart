import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/models/chat.dart';
import 'core/models/api_config.dart';
import 'core/models/message.dart';
import 'features/navigation/app_scaffold.dart';
import 'features/settings/screens/settings_screen.dart';
import 'l10n/translations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(ChatAdapter());
  Hive.registerAdapter(ApiConfigAdapter());
  Hive.registerAdapter(MessageAdapter());

  // Open Hive boxes
  await Hive.openBox<Chat>('chats');
  await Hive.openBox<ApiConfig>('api_configs');
  await Hive.openBox<Map>('favorites');

  runApp(const ProviderScope(child: AIChatApp()));
}

class AIChatApp extends ConsumerWidget {
  const AIChatApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(languageProvider);
    final l10n = AppLocalizations.of(context);
    return MaterialApp(
      title: l10n.get('app_title'),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const AppScaffold(),
    );
  }
}
