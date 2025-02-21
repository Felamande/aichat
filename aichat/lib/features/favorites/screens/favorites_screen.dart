import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../controllers/favorites_controller.dart';
import '../../chat/screens/chat_screen.dart';
import '../../search/screens/search_screen.dart';
import '../models/favorite_item.dart';
import '../../../core/models/chat.dart';
import '../../../core/models/message.dart';
import '../../../l10n/translations.dart';
import './favorite_detail_screen.dart';

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, List<FavoriteItem>>((ref) {
  return FavoritesNotifier();
});

class FavoritesNotifier extends StateNotifier<List<FavoriteItem>> {
  FavoritesNotifier() : super([]);

  void addFavorite(FavoriteItem item) {
    if (!state.any((element) => element.id == item.id)) {
      state = [...state, item];
    }
  }

  void removeFavorite(String id) {
    state = state.where((item) => item.id != id).toList();
  }
}

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref
        .watch(favoritesControllerProvider)
        .where((item) => !item.isChat) // Only show message favorites
        .toList();
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('favorites')),
      ),
      body: favorites.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.star_outline,
                    size: 64,
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.get('no_favorites'),
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.get('favorites_hint'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final favorite = favorites[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: Icon(
                      Icons.message,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(favorite.title),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          favorite.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (favorite.reasoningContent != null)
                          Text(
                            favorite.reasoningContent!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withOpacity(0.7),
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat.yMd().add_jm().format(favorite.timestamp),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        ref
                            .read(favoritesControllerProvider.notifier)
                            .removeFavorite(favorite.id);
                      },
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FavoriteDetailScreen(
                            favorite: favorite,
                            l10n: l10n,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
