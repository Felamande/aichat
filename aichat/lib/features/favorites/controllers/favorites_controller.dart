import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/models/chat.dart';
import '../../../core/models/message.dart';
import '../models/favorite_item.dart';

final favoritesControllerProvider =
    StateNotifierProvider<FavoritesController, List<FavoriteItem>>((ref) {
  return FavoritesController();
});

class FavoritesController extends StateNotifier<List<FavoriteItem>> {
  FavoritesController() : super([]) {
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      final box = await Hive.openBox<Map>('favorites');
      final favorites = box.values
          .map((item) => FavoriteItem.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      state = favorites;
    } catch (e) {
      // Handle error
      state = [];
    }
  }

  Future<void> _saveFavorites() async {
    try {
      final box = await Hive.openBox<Map>('favorites');
      await box.clear();
      await box.addAll(state.map((item) => item.toJson()));
    } catch (e) {
      // Handle error
    }
  }

  Future<void> addFavorite(FavoriteItem item) async {
    if (!state.any((element) => element.id == item.id)) {
      state = [...state, item];
      await _saveFavorites();
    }
  }

  Future<void> removeFavorite(String id) async {
    state = state.where((item) => item.id != id).toList();
    await _saveFavorites();
  }

  bool isFavorite(String id) {
    return state.any((item) => item.id == id);
  }

  Future<void> toggleFavorite(Chat chat, [Message? message]) async {
    final item = message != null
        ? FavoriteItem.fromMessage(message, chat)
        : FavoriteItem.fromChat(chat);

    if (isFavorite(item.id)) {
      await removeFavorite(item.id);
    } else {
      await addFavorite(item);
    }
  }
}
