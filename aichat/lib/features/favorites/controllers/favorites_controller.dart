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

  Future<void> toggleMessageFavorite(Message message, Chat chat) async {
    final box = await Hive.openBox<Map>('favorites');
    final existingIndex = state.indexWhere((item) => item.id == message.id);

    if (existingIndex != -1) {
      // Remove from favorites
      await box.delete(message.id);
      state = state.where((item) => item.id != message.id).toList();
    } else {
      // Add to favorites
      final favorite = FavoriteItem.fromMessage(message, chat);
      await box.put(message.id, favorite.toJson());
      state = [...state, favorite];
    }
  }

  Future<void> updateFavorite(FavoriteItem updatedFavorite) async {
    final box = await Hive.openBox<Map>('favorites');
    await box.put(updatedFavorite.id, updatedFavorite.toJson());
    state = state
        .map((item) => item.id == updatedFavorite.id ? updatedFavorite : item)
        .toList();
  }

  Future<void> toggleChatFavorite(Chat chat) async {
    final box = await Hive.openBox<Map>('favorites');
    final existingIndex =
        state.indexWhere((item) => item.id == chat.id && item.isChat);

    if (existingIndex != -1) {
      // Remove from favorites
      await box.delete(chat.id);
      state =
          state.where((item) => !(item.id == chat.id && item.isChat)).toList();
    } else {
      // Add to favorites
      final favorite = FavoriteItem.fromChat(chat);
      await box.put(chat.id, favorite.toJson());
      state = [...state, favorite];
    }
  }

  // This method is now only used for cleaning up message favorites when a chat is deleted
  Future<void> removeAllForChat(String chatId) async {
    final box = await Hive.openBox<Map>('favorites');

    // Only remove chat favorite, keep message favorites
    final chatFavorites = state
        .where(
          (item) => item.id == chatId && item.isChat,
        )
        .toList();

    if (chatFavorites.isNotEmpty) {
      await box.delete(chatId);
      state =
          state.where((item) => !(item.id == chatId && item.isChat)).toList();
    }
  }
}
