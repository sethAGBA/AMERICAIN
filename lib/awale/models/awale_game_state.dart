import 'package:equatable/equatable.dart';
import 'awale_player.dart';
import 'awale_move.dart';

/// Represents the complete state of an Awale game
class AwaleGameState extends Equatable {
  final String gameId;
  final List<int> pits; // 12 pits: [0-5] top row, [6-11] bottom row
  final List<AwalePlayer> players; // Always 2 players
  final int currentPlayerIndex; // 0 or 1
  final Map<String, int> captures; // playerId -> number of seeds captured
  final GameStatus status;
  final List<AwaleMove> moveHistory;
  final String? winnerId;
  final String hostId; // For multiplayer
  final GameMode mode; // Local or online

  const AwaleGameState({
    required this.gameId,
    required this.pits,
    required this.players,
    this.currentPlayerIndex = 0,
    this.captures = const {},
    this.status = GameStatus.waiting,
    this.moveHistory = const [],
    this.winnerId,
    required this.hostId,
    this.mode = GameMode.local,
  });

  /// Create initial game state
  factory AwaleGameState.initial({
    required String gameId,
    required List<AwalePlayer> players,
    required String hostId,
    GameMode mode = GameMode.local,
  }) {
    return AwaleGameState(
      gameId: gameId,
      pits: List.filled(12, 4), // Each pit starts with 4 seeds
      players: players,
      currentPlayerIndex: 0,
      captures: {players[0].id: 0, players[1].id: 0},
      status: GameStatus.waiting,
      moveHistory: [],
      hostId: hostId,
      mode: mode,
    );
  }

  /// Get current player
  AwalePlayer get currentPlayer => players[currentPlayerIndex];

  /// Get opponent player
  AwalePlayer get opponentPlayer => players[1 - currentPlayerIndex];

  /// Get pit indices for a specific player
  List<int> getPitIndicesForPlayer(AwalePlayer player) {
    if (player.side == PlayerSide.top) {
      return [0, 1, 2, 3, 4, 5];
    } else {
      return [6, 7, 8, 9, 10, 11];
    }
  }

  /// Get total seeds on board
  int get totalSeedsOnBoard => pits.fold(0, (sum, seeds) => sum + seeds);

  /// Check if game is over
  bool get isGameOver => status == GameStatus.finished;

  /// Create a copy with updated fields
  AwaleGameState copyWith({
    String? gameId,
    List<int>? pits,
    List<AwalePlayer>? players,
    int? currentPlayerIndex,
    Map<String, int>? captures,
    GameStatus? status,
    List<AwaleMove>? moveHistory,
    String? winnerId,
    String? hostId,
    GameMode? mode,
  }) {
    return AwaleGameState(
      gameId: gameId ?? this.gameId,
      pits: pits ?? List.from(this.pits),
      players: players ?? this.players,
      currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
      captures: captures ?? Map.from(this.captures),
      status: status ?? this.status,
      moveHistory: moveHistory ?? List.from(this.moveHistory),
      winnerId: winnerId ?? this.winnerId,
      hostId: hostId ?? this.hostId,
      mode: mode ?? this.mode,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'gameId': gameId,
      'pits': pits,
      'players': players.map((p) => p.toJson()).toList(),
      'currentPlayerIndex': currentPlayerIndex,
      'captures': captures,
      'status': status.name,
      'moveHistory': moveHistory.map((m) => m.toJson()).toList(),
      'winnerId': winnerId,
      'hostId': hostId,
      'mode': mode.name,
    };
  }

  /// Create from JSON
  factory AwaleGameState.fromJson(Map<String, dynamic> json) {
    return AwaleGameState(
      gameId: json['gameId'] as String,
      pits: (json['pits'] as List<dynamic>).map((e) => e as int).toList(),
      players: (json['players'] as List<dynamic>)
          .map((p) => AwalePlayer.fromJson(p as Map<String, dynamic>))
          .toList(),
      currentPlayerIndex: json['currentPlayerIndex'] as int,
      captures: (json['captures'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, value as int),
      ),
      status: GameStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => GameStatus.waiting,
      ),
      moveHistory:
          (json['moveHistory'] as List<dynamic>?)
              ?.map((m) => AwaleMove.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
      winnerId: json['winnerId'] as String?,
      hostId: json['hostId'] as String,
      mode: GameMode.values.firstWhere(
        (e) => e.name == json['mode'],
        orElse: () => GameMode.local,
      ),
    );
  }

  @override
  List<Object?> get props => [
    gameId,
    pits,
    players,
    currentPlayerIndex,
    captures,
    status,
    moveHistory,
    winnerId,
    hostId,
    mode,
  ];
}

/// Game status enum
enum GameStatus {
  waiting, // Waiting for players
  playing, // Game in progress
  finished, // Game completed
}

/// Game mode enum
enum GameMode {
  local, // Pass-and-play
  online, // Online multiplayer
}
