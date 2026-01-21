import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final recentGamesProvider =
    StateNotifierProvider<RecentGamesNotifier, List<String>>((ref) {
      return RecentGamesNotifier();
    });

class RecentGamesNotifier extends StateNotifier<List<String>> {
  static const String _storageKey = 'recent_games';
  static const int _maxItems = 3;

  RecentGamesNotifier() : super([]) {
    _loadRecentGames();
  }

  Future<void> _loadRecentGames() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final gamesJson = prefs.getString(_storageKey);
      if (gamesJson != null) {
        final List<dynamic> decoded = jsonDecode(gamesJson);
        state = decoded.map((e) => e.toString()).toList();
      }
    } catch (_) {}
  }

  Future<void> _saveRecentGames() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(state));
    } catch (_) {}
  }

  void addGame(String gameId) {
    // Remove if already exists to move it to the top
    final List<String> newList = state.where((id) => id != gameId).toList();

    // Add to top
    newList.insert(0, gameId);

    // Limit size
    if (newList.length > _maxItems) {
      state = newList.sublist(0, _maxItems);
    } else {
      state = newList;
    }

    _saveRecentGames();
  }
}
