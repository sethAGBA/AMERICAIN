import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, List<String>>((ref) {
      return FavoritesNotifier();
    });

class FavoritesNotifier extends StateNotifier<List<String>> {
  static const String _storageKey = 'favorite_games';

  FavoritesNotifier() : super([]) {
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getString(_storageKey);
      if (favoritesJson != null) {
        final List<dynamic> decoded = jsonDecode(favoritesJson);
        state = decoded.map((e) => e.toString()).toList();
      }
    } catch (e) {
      // Keep default state if loading fails
    }
  }

  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(state));
    } catch (e) {
      // Handle error if needed
    }
  }

  void toggleFavorite(String gameId) {
    if (state.contains(gameId)) {
      state = state.where((id) => id != gameId).toList();
    } else {
      state = [...state, gameId];
    }
    _saveFavorites();
  }

  bool isFavorite(String gameId) {
    return state.contains(gameId);
  }
}
