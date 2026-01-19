enum MorpionSymbol { x, o, none }

class MorpionPlayer {
  final String id;
  final String name;
  final MorpionSymbol symbol;
  final bool isBot;

  const MorpionPlayer({
    required this.id,
    required this.name,
    required this.symbol,
    this.isBot = false,
  });
}

enum MorpionStatus { lobby, playing, finished }

class MorpionState {
  final List<MorpionSymbol> board;
  final List<MorpionPlayer> players;
  final int currentTurn;
  final MorpionStatus status;
  final String? winnerId;
  final List<int>? winningLine;
  final bool isDraw;

  MorpionState({
    required this.board,
    required this.players,
    required this.currentTurn,
    required this.status,
    this.winnerId,
    this.winningLine,
    this.isDraw = false,
  });

  MorpionState copyWith({
    List<MorpionSymbol>? board,
    List<MorpionPlayer>? players,
    int? currentTurn,
    MorpionStatus? status,
    String? winnerId,
    List<int>? winningLine,
    bool? isDraw,
  }) {
    return MorpionState(
      board: board ?? this.board,
      players: players ?? this.players,
      currentTurn: currentTurn ?? this.currentTurn,
      status: status ?? this.status,
      winnerId: winnerId ?? this.winnerId,
      winningLine: winningLine ?? this.winningLine,
      isDraw: isDraw ?? this.isDraw,
    );
  }
}
