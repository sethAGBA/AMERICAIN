import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_stats.dart';

class StatsService {
  static const String _statsKey = 'user_game_stats';

  // Singleton pattern
  static final StatsService _instance = StatsService._internal();
  factory StatsService() => _instance;
  StatsService._internal();

  Future<List<GameStats>> loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    final String? statsJson = prefs.getString(_statsKey);

    if (statsJson == null) {
      return [];
    }

    try {
      final List<dynamic> decoded = jsonDecode(statsJson);
      return decoded.map((e) => GameStats.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error loading stats: $e');
      return [];
    }
  }

  Future<void> saveStats(List<GameStats> stats) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(stats.map((e) => e.toJson()).toList());
    await prefs.setString(_statsKey, encoded);
  }

  Future<void> incrementWin(String gameId) async {
    final stats = await loadStats();
    final index = stats.indexWhere((s) => s.gameId == gameId);

    if (index != -1) {
      final current = stats[index];
      stats[index] = current.copyWith(wins: current.wins + 1);
    } else {
      stats.add(GameStats(gameId: gameId, wins: 1));
    }

    await saveStats(stats);
  }

  Future<void> incrementLoss(String gameId) async {
    final stats = await loadStats();
    final index = stats.indexWhere((s) => s.gameId == gameId);

    if (index != -1) {
      final current = stats[index];
      stats[index] = current.copyWith(losses: current.losses + 1);
    } else {
      stats.add(GameStats(gameId: gameId, losses: 1));
    }

    await saveStats(stats);
  }

  Future<GameStats> getStatsForGame(String gameId) async {
    final stats = await loadStats();
    return stats.firstWhere(
      (s) => s.gameId == gameId,
      orElse: () => GameStats(gameId: gameId),
    );
  }
}
