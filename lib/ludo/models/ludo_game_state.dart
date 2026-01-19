import 'ludo_player.dart';
import 'ludo_piece.dart'; // Needed for LudoColor

enum LudoTurnState {
  waitingForRoll,
  waitingForMove,
  moving, // Animation state
  finished,
}

class LudoGameState {
  final List<LudoPlayer> players;
  final int currentPlayerIndex;
  final List<int> diceValues;
  final List<int>
  selectedDiceIndices; // Indices of the selected dice in diceValues
  final LudoTurnState turnState;
  final List<LudoColor> winners; // Track order of finishing

  const LudoGameState({
    required this.players,
    required this.currentPlayerIndex,
    this.diceValues = const [],
    this.selectedDiceIndices = const [],
    this.turnState = LudoTurnState.waitingForRoll,
    this.winners = const [],
  });

  factory LudoGameState.initial() {
    return LudoGameState(
      players: [
        LudoPlayer.initial(LudoColor.red, PlayerType.human),
        LudoPlayer.initial(LudoColor.green, PlayerType.human),
        LudoPlayer.initial(LudoColor.yellow, PlayerType.human),
        LudoPlayer.initial(LudoColor.blue, PlayerType.human),
      ],
      currentPlayerIndex: 0,
      diceValues: [],
      selectedDiceIndices: [],
    );
  }

  LudoPlayer get currentPlayer => players[currentPlayerIndex];

  LudoGameState copyWith({
    List<LudoPlayer>? players,
    int? currentPlayerIndex,
    List<int>? diceValues,
    List<int>? selectedDiceIndices,
    LudoTurnState? turnState,
    List<LudoColor>? winners,
  }) {
    // Reset selection if dice values changed, unless override provided
    final newDiceValues = diceValues ?? this.diceValues;
    final newSelectedDice = diceValues != null
        ? <int>[]
        : (selectedDiceIndices ?? this.selectedDiceIndices);

    return LudoGameState(
      players: players ?? this.players,
      currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
      diceValues: newDiceValues,
      selectedDiceIndices: newSelectedDice,
      turnState: turnState ?? this.turnState,
      winners: winners ?? this.winners,
    );
  }

  Map<String, dynamic> toJson() => {
    'players': players.map((p) => p.toJson()).toList(),
    'currentPlayerIndex': currentPlayerIndex,
    'diceValues': diceValues,
    'selectedDiceIndices': selectedDiceIndices,
    'turnState': turnState.index,
    'winners': winners.map((w) => w.index).toList(),
  };

  factory LudoGameState.fromJson(Map<String, dynamic> json) => LudoGameState(
    players: (json['players'] as List)
        .map((p) => LudoPlayer.fromJson(p))
        .toList(),
    currentPlayerIndex: json['currentPlayerIndex'],
    diceValues: List<int>.from(json['diceValues']),
    selectedDiceIndices: List<int>.from(json['selectedDiceIndices']),
    turnState: LudoTurnState.values[json['turnState']],
    winners: (json['winners'] as List)
        .map((w) => LudoColor.values[w as int])
        .toList(),
  );
}
