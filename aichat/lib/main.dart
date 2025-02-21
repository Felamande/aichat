import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/models/message.dart';
import 'core/models/chat.dart';
import 'core/models/api_config.dart';
import 'features/navigation/app_scaffold.dart';
import 'features/settings/screens/settings_screen.dart';
import 'shared/themes/app_theme.dart';
import 'l10n/app_localizations_delegate.dart';
import 'l10n/translations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(MessageAdapter());
  Hive.registerAdapter(ChatAdapter());
  Hive.registerAdapter(ApiConfigAdapter());
  Hive.registerAdapter(AttachmentAdapter());

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

    return MaterialApp(
      title: 'AIChat',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: const Locale('zh'), // Set Chinese as default
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const AppScaffold(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AIChat')),
      body: const Center(child: Text('Welcome to AIChat')),
    );
  }
}
