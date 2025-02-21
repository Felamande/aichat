import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../chat/screens/chat_list_screen.dart';
import '../favorites/screens/favorites_screen.dart';
import '../profile/screens/profile_screen.dart';
import '../../../l10n/translations.dart';

final navigationIndexProvider = StateProvider<int>((ref) => 0);

class AppScaffold extends ConsumerWidget {
  const AppScaffold({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationIndexProvider);
    final l18n = AppLocalizations.of(context);

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: const [
          ChatListScreen(),
          FavoritesScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          ref.read(navigationIndexProvider.notifier).state = index;
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.chat_outlined),
            selectedIcon: const Icon(Icons.chat),
            label: l18n.get('chats'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.star_outline),
            selectedIcon: const Icon(Icons.star),
            label: l18n.get('favorites'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: l18n.get('profile'),
          ),
        ],
      ),
    );
  }
}
