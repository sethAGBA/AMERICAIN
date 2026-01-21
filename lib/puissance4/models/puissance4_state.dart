import 'dart:math';

import 'puissance4_player.dart';

class Puissance4State {
  final List<Puissance4Player> players;
  final List<List<Puissance4Color?>> board; // 6 rows x 7 columns
  final String currentPlayerId;
  final String? winnerId;
  final bool isDraw;
  final List<Point<int>> winningCells;
  final BotDifficulty botDifficulty;

  const Puissance4State({
    required this.players,
    required this.board,
    required this.currentPlayerId,
    this.winnerId,
    this.isDraw = false,
    this.winningCells = const [],
    this.botDifficulty = BotDifficulty.easy,
  });

  factory Puissance4State.initial() {
    return const Puissance4State(players: [], board: [], currentPlayerId: '');
  }

  Puissance4State copyWith({
    List<Puissance4Player>? players,
    List<List<Puissance4Color?>>? board,
    String? currentPlayerId,
    String? winnerId,
    bool? isDraw,
    List<Point<int>>? winningCells,
    BotDifficulty? botDifficulty,
  }) {
    return Puissance4State(
      players: players ?? this.players,
      board: board ?? this.board,
      currentPlayerId: currentPlayerId ?? this.currentPlayerId,
      winnerId: winnerId ?? this.winnerId, // Allow null
      isDraw: isDraw ?? this.isDraw,
      winningCells: winningCells ?? this.winningCells,
      botDifficulty: botDifficulty ?? this.botDifficulty,
    );
  }

  Puissance4Player? get currentPlayer {
    try {
      return players.firstWhere((p) => p.id == currentPlayerId);
    } catch (_) {
      return null;
    }
  }

  Puissance4Player? get winner {
    if (winnerId == null) return null;
    try {
      return players.firstWhere((p) => p.id == winnerId);
    } catch (_) {
      return null;
    }
  }

  bool get isGameOver => winnerId != null || isDraw;
}

enum BotDifficulty { easy, medium, hard }
